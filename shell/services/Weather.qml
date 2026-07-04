pragma Singleton

import QtQuick
import Quickshell
import Caelestia
import Caelestia.Config
import qs.utils

Singleton {
    id: root

    property string city
    property string loc
    property var cc
    property list<var> forecast
    property list<var> hourlyForecast
    property int weatherRequestGeneration
    property int openMeteoSuccessGeneration

    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc ?? qsTr("No weather")
    readonly property string temp: formatTemp(cc?.tempC)
    readonly property string feelsLike: formatTemp(cc?.feelsLikeC)
    readonly property int humidity: cc?.humidity ?? 0
    readonly property real windSpeed: cc?.windSpeed ?? 0
    readonly property string sunrise: cc ? formatWeatherTime(cc.sunrise) : "--:--"
    readonly property string sunset: cc ? formatWeatherTime(cc.sunset) : "--:--"

    readonly property var cachedCities: new Map()

    function formatTemp(temp: var): string {
        return GlobalConfig.services.useFahrenheit ? `${temp !== undefined ? Math.round(toFahrenheit(temp)) : "--"}°F` : `${temp !== undefined ? Math.round(temp) : "--"}°C`;
    }

    function formatWeatherTime(value: var): string {
        const date = weatherDate(value);
        if (!date)
            return "--:--";

        return Qt.formatDateTime(date, GlobalConfig.services.useTwelveHourClock ? "h:mm A" : "h:mm");
    }

    function weatherDate(value: var): var {
        if (!value)
            return null;

        const date = new Date(String(value).replace(/-/g, "/").replace("T", " "));
        return isNaN(date.getTime()) ? null : date;
    }

    function reload(): void {
        const configLocation = GlobalConfig.services.weatherLocation;

        if (configLocation) {
            if (configLocation.indexOf(",") !== -1 && !isNaN(parseFloat(configLocation.split(",")[0]))) {
                loc = configLocation;
                fetchCityFromCoords(configLocation);
            } else {
                fetchCoordsFromCity(configLocation);
            }
        } else if (!loc || timer.elapsed() > 900) {
            Requests.get("https://ipinfo.io/json", text => {
                const response = JSON.parse(text);
                if (response.loc) {
                    loc = response.loc;
                    city = response.city ?? "";
                    timer.restart();
                }
            });
        }
    }

    function fetchCityFromCoords(coords: string): void {
        if (cachedCities.has(coords)) {
            city = cachedCities.get(coords);
            return;
        }

        const [lat, lon] = coords.split(",").map(s => s.trim());

        const fallbackToBigDataCloud = () => {
            const fallbackUrl = `https://api.bigdatacloud.net/data/reverse-geocode-client?latitude=${lat}&longitude=${lon}&localityLanguage=en`;
            Requests.get(fallbackUrl, text => {
                const geo = JSON.parse(text);
                const geoCity = geo.city || geo.locality;
                if (geoCity) {
                    city = geoCity;
                    cachedCities.set(coords, geoCity);
                } else {
                    city = "Unknown City";
                }
            });
        };

        const nominatimUrl = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lon}&format=geocodejson`;
        Requests.get(nominatimUrl, text => {
            const geo = JSON.parse(text).features?.[0]?.properties.geocoding;
            if (geo) {
                const geoCity = geo.type === "city" ? geo.name : geo.city;
                if (geoCity) {
                    city = geoCity;
                    cachedCities.set(coords, geoCity);
                    return;
                }
            }
            fallbackToBigDataCloud();
        }, fallbackToBigDataCloud);
    }

    function fetchCoordsFromCity(cityName: string): void {
        const url = `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(cityName)}&count=1&language=en&format=json`;

        Requests.get(url, text => {
            const json = JSON.parse(text);
            if (json.results && json.results.length > 0) {
                const result = json.results[0];
                loc = result.latitude + "," + result.longitude;
                city = result.name;
            } else {
                loc = "";
                reload();
            }
        });
    }

    function fetchWeatherData(): void {
        const url = getWeatherUrl();
        if (url === "")
            return;

        const generation = ++weatherRequestGeneration;
        fetchWttrWeatherData(generation);

        Requests.get(url, text => {
            try {
                const json = JSON.parse(text);
                if (parseOpenMeteoWeatherData(json))
                    openMeteoSuccessGeneration = generation;
                else
                    fetchWttrWeatherData(generation);
            } catch (e) {
                fetchWttrWeatherData(generation);
            }
        }, () => fetchWttrWeatherData(generation));
    }

    function parseOpenMeteoWeatherData(json: var): bool {
        if (!json.current || !json.daily || !json.hourly)
            return false;

        cc = {
            weatherCode: json.current.weather_code,
            weatherDesc: getWeatherCondition(json.current.weather_code),
            tempC: json.current.temperature_2m,
            feelsLikeC: json.current.apparent_temperature,
            humidity: json.current.relative_humidity_2m,
            windSpeed: json.current.wind_speed_10m,
            isDay: json.current.is_day,
            sunrise: json.daily.sunrise[0].replace("T", " "),
            sunset: json.daily.sunset[0].replace("T", " ")
        };

        const forecastList = [];
        for (let i = 0; i < json.daily.time.length; i++)
            forecastList.push({
                date: json.daily.time[i].replace(/-/g, "/"),
                maxTempC: json.daily.temperature_2m_max[i],
                minTempC: json.daily.temperature_2m_min[i],
                weatherCode: json.daily.weather_code[i],
                icon: Icons.getWeatherIcon(json.daily.weather_code[i])
            });
        forecast = forecastList;

        const hourlyList = [];
        const now = new Date();
        for (let i = 0; i < json.hourly.time.length; i++) {
            const time = new Date(json.hourly.time[i].replace("T", " "));

            if (time < now)
                continue;

            hourlyList.push({
                timestamp: json.hourly.time[i],
                hour: time.getHours(),
                tempC: Math.round(json.hourly.temperature_2m[i]),
                precipChance: json.hourly.precipitation_probability[i],
                weatherCode: json.hourly.weather_code[i],
                icon: Icons.getWeatherIcon(json.hourly.weather_code[i])
            });
        }
        hourlyForecast = hourlyList;
        return true;
    }

    function fetchWttrWeatherData(generation: var): void {
        const url = getWttrWeatherUrl();
        if (url === "")
            return;

        const requestGeneration = generation === undefined ? weatherRequestGeneration : generation;
        Requests.get(url, text => {
            try {
                parseWttrWeatherData(JSON.parse(text), requestGeneration);
            } catch (e) {}
        });
    }

    function parseWttrWeatherData(json: var, generation: var): bool {
        if (generation !== weatherRequestGeneration || openMeteoSuccessGeneration === generation)
            return false;

        if (!json.current_condition || json.current_condition.length === 0 || !json.weather || json.weather.length === 0)
            return false;

        const current = json.current_condition[0];
        const today = json.weather[0];
        const astronomy = today.astronomy && today.astronomy.length > 0 ? today.astronomy[0] : {};
        const currentCode = wttrToWmoCode(current.weatherCode);
        const desc = current.weatherDesc && current.weatherDesc.length > 0 ? current.weatherDesc[0].value : getWeatherCondition(currentCode);

        cc = {
            weatherCode: currentCode,
            weatherDesc: desc,
            tempC: numberOr(current.temp_C, 0),
            feelsLikeC: numberOr(current.FeelsLikeC, numberOr(current.temp_C, 0)),
            humidity: numberOr(current.humidity, 0),
            windSpeed: numberOr(current.windspeedKmph, 0),
            isDay: 1,
            sunrise: dateTimeFromWttrTime(today.date, astronomy.sunrise),
            sunset: dateTimeFromWttrTime(today.date, astronomy.sunset)
        };

        const forecastList = [];
        for (let i = 0; i < json.weather.length; i++) {
            const day = json.weather[i];
            const dayCode = wttrToWmoCode(representativeWttrCode(day));
            forecastList.push({
                date: day.date.replace(/-/g, "/"),
                maxTempC: numberOr(day.maxtempC, 0),
                minTempC: numberOr(day.mintempC, 0),
                weatherCode: dayCode,
                icon: Icons.getWeatherIcon(dayCode)
            });
        }
        forecast = forecastList;

        const hourlyList = [];
        const now = new Date();
        for (let i = 0; i < json.weather.length; i++) {
            const day = json.weather[i];
            if (!day.hourly)
                continue;

            for (let j = 0; j < day.hourly.length; j++) {
                const hour = day.hourly[j];
                const hourNumber = Math.floor(numberOr(hour.time, 0) / 100);
                const timestamp = day.date + "T" + twoDigits(hourNumber) + ":00";
                const time = new Date(timestamp.replace("T", " "));

                if (time < now)
                    continue;

                const hourCode = wttrToWmoCode(hour.weatherCode);
                hourlyList.push({
                    timestamp,
                    hour: hourNumber,
                    tempC: Math.round(numberOr(hour.tempC, 0)),
                    precipChance: numberOr(hour.chanceofrain, 0),
                    weatherCode: hourCode,
                    icon: Icons.getWeatherIcon(hourCode)
                });
            }
        }
        hourlyForecast = hourlyList;
        return true;
    }

    function toFahrenheit(celcius: real): real {
        return celcius * 9 / 5 + 32;
    }

    function getWeatherUrl(): string {
        if (!loc || loc.indexOf(",") === -1)
            return "";

        const [lat, lon] = loc.split(",").map(s => s.trim());
        const baseUrl = "https://api.open-meteo.com/v1/forecast";
        const params = ["latitude=" + lat, "longitude=" + lon, "hourly=weather_code,temperature_2m,precipitation_probability", "daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset", "current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,weather_code,wind_speed_10m", "timezone=auto", "forecast_days=7"];

        return baseUrl + "?" + params.join("&");
    }

    function getWttrWeatherUrl(): string {
        if (!loc || loc.indexOf(",") === -1)
            return "";

        const [lat, lon] = loc.split(",").map(s => s.trim());
        return `https://wttr.in/${lat},${lon}?format=j1`;
    }

    function dateTimeFromWttrTime(date: string, time: string): string {
        const parsedTime = parseWttrClockTime(time);
        if (!parsedTime)
            return "";

        return `${date.replace(/-/g, "/")} ${twoDigits(parsedTime.hour)}:${twoDigits(parsedTime.minute)}`;
    }

    function numberOr(value: var, fallback: var): var {
        const number = Number(value);
        return isNaN(number) ? fallback : number;
    }

    function twoDigits(value: int): string {
        return value < 10 ? "0" + value : "" + value;
    }

    function parseWttrClockTime(time: string): var {
        const match = String(time ?? "").match(/^(\d{1,2}):(\d{2})\s*([AP]M)$/i);
        if (!match)
            return null;

        let hour = Number(match[1]);
        const minute = Number(match[2]);
        const period = match[3].toUpperCase();

        if (period === "PM" && hour !== 12)
            hour += 12;
        else if (period === "AM" && hour === 12)
            hour = 0;

        return {
            hour,
            minute
        };
    }

    function representativeWttrCode(day: var): string {
        if (!day.hourly || day.hourly.length === 0)
            return "0";

        for (let i = 0; i < day.hourly.length; i++) {
            if (Number(day.hourly[i].time) >= 1200)
                return day.hourly[i].weatherCode;
        }

        return day.hourly[Math.floor(day.hourly.length / 2)].weatherCode;
    }

    function wttrToWmoCode(code: var): string {
        const codes = {
            "113": "0",
            "116": "2",
            "119": "3",
            "122": "3",
            "143": "45",
            "176": "61",
            "179": "71",
            "182": "71",
            "185": "71",
            "200": "95",
            "227": "71",
            "230": "75",
            "248": "45",
            "260": "45",
            "263": "51",
            "266": "53",
            "281": "56",
            "284": "57",
            "293": "61",
            "296": "61",
            "299": "63",
            "302": "65",
            "305": "63",
            "308": "65",
            "311": "56",
            "314": "57",
            "317": "71",
            "320": "73",
            "323": "71",
            "326": "71",
            "329": "73",
            "332": "75",
            "335": "75",
            "338": "75",
            "350": "77",
            "353": "61",
            "356": "63",
            "359": "65",
            "362": "71",
            "365": "71",
            "368": "71",
            "371": "75",
            "374": "71",
            "377": "77",
            "386": "95",
            "389": "95",
            "392": "95",
            "395": "96"
        };
        return codes[String(code)] || "3";
    }

    function getWeatherCondition(code: string): string {
        const conditions = {
            "0": "Clear",
            "1": "Clear",
            "2": "Partly cloudy",
            "3": "Overcast",
            "45": "Fog",
            "48": "Fog",
            "51": "Drizzle",
            "53": "Drizzle",
            "55": "Drizzle",
            "56": "Freezing drizzle",
            "57": "Freezing drizzle",
            "61": "Light rain",
            "63": "Rain",
            "65": "Heavy rain",
            "66": "Light rain",
            "67": "Heavy rain",
            "71": "Light snow",
            "73": "Snow",
            "75": "Heavy snow",
            "77": "Snow",
            "80": "Light rain",
            "81": "Rain",
            "82": "Heavy rain",
            "85": "Light snow showers",
            "86": "Heavy snow showers",
            "95": "Thunderstorm",
            "96": "Thunderstorm with hail",
            "99": "Thunderstorm with hail"
        };
        return conditions[code] || "Unknown";
    }

    onLocChanged: fetchWeatherData()

    Connections {
        function onWeatherLocationChanged(): void {
            root.reload();
        }

        target: GlobalConfig.services
    }

    Timer {
        interval: 3600000 // 1 hour
        running: true
        repeat: true
        onTriggered: fetchWeatherData()
    }

    ElapsedTimer {
        id: timer
    }
}
