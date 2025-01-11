import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Position;

class Face1View extends WatchUi.WatchFace {
    // Config
    const BatteryWarnThreshold = 15.0; // Display battery warn icon if below [%]

    // Anchors are hard-coded for round watch face with 390x390 pixels
    // Icons are drawn above anchor, Text below anchor
    const DataOrder = [ "hr", "bb", "steps", null, "sunrise", "sunset" ];
    const DataOrderPhoneConnected = [ "hr", "bb", "steps", null, "sunriseAndSet", "weather" ];
    const DataAnchors = [
        [115, 92],
        [195, 67],
        [275, 92],
        [195, 305], // Single Data Icon with long text
        [125, 275],
        [265, 275]];
    const LowBatAnchor = [195, 320];
    const PhoneConnectAnchor = [195, 285];
    const DayTextAnchor = [195, 128];

    // if true, WeekDays is used to print week day, system default otherwise
    const OverrideWeekDayString = true;
    const WeekDays = {
        1 => "So",
        2 => "Mo",
        3 => "Di",
        4 => "Mi",
        5 => "Do",
        6 => "Fr",
        7 => "Sa"};

    var MonoFont;
    var MonoFontLargeNum;

    var Icons as Dictionary<String, BitmapResource> = {
        "hr" => null as BitmapResource,
        "bb" => null as BitmapResource,
        "steps" => null as BitmapResource,
        // "sun" => null as BitmapResource,
        "sunrise" => null as BitmapResource,
        "sunset" => null as BitmapResource,
        "lowbat" => null as BitmapResource,
        "phone_0"  => null as BitmapResource,
        "phone_1"  => null as BitmapResource,
        "phone_2"  => null as BitmapResource,
        "phone_3"  => null as BitmapResource};

    function initialize() {
        WatchFace.initialize();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        Icons["hr"] = Application.loadResource( Rez.Drawables.icon_hr ) as BitmapResource;
        Icons["bb"] = Application.loadResource( Rez.Drawables.icon_bb ) as BitmapResource;
        Icons["steps"] = Application.loadResource( Rez.Drawables.icon_steps ) as BitmapResource;
        // Icons["sun"] = Application.loadResource( Rez.Drawables.icon_sun ) as BitmapResource;
        Icons["sunrise"] = Application.loadResource( Rez.Drawables.icon_sunrise ) as BitmapResource;
        Icons["sunset"] = Application.loadResource( Rez.Drawables.icon_sunset ) as BitmapResource;
        Icons["lowbat"] = Application.loadResource( Rez.Drawables.icon_lowbat ) as BitmapResource;
        Icons["phone_0"] = Application.loadResource( Rez.Drawables.icon_phone_0 ) as BitmapResource;
        Icons["phone_1"] = Application.loadResource( Rez.Drawables.icon_phone_1 ) as BitmapResource;
        Icons["phone_2"] = Application.loadResource( Rez.Drawables.icon_phone_2 ) as BitmapResource;
        Icons["phone_3"] = Application.loadResource( Rez.Drawables.icon_phone_3 ) as BitmapResource;

        MonoFont = Application.loadResource( Rez.Fonts.MonoFont ) as FontResource;
        MonoFontLargeNum = Application.loadResource( Rez.Fonts.MonoFontLargeNum ) as FontResource;
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.clear();

        // Main clock
        var clockTime = System.getClockTime();
        var timeString = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(dc.getWidth() / 2,
                    dc.getHeight() / 2,
                    MonoFontLargeNum,
                    timeString,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);

        // Day string
        var Now;
        var DayString;
        if(OverrideWeekDayString)
        {
            Now = Time.Gregorian.info(Time.now(), Time.FORMAT_SHORT);
            DayString = Lang.format("$1$ $2$", [WeekDays[Now.day_of_week], Now.day]);
        }
        else
        {
            Now = Time.Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
            DayString = Lang.format("$1$ $2$", [Now.day_of_week, Now.day]);
        }

        dc.drawText(DayTextAnchor[0],
                    DayTextAnchor[1],
                    MonoFont,
                    DayString,
                    Graphics.TEXT_JUSTIFY_CENTER);

        // Low battery icon
        if( System.getSystemStats().battery < BatteryWarnThreshold )
        {
            dc.drawBitmap(LowBatAnchor[0] - Icons["lowbat"].getWidth() / 2,
                          LowBatAnchor[1] - Icons["lowbat"].getHeight(),
                          Icons["lowbat"]);
        }

        // Phone/Notifications icon
        if( System.getDeviceSettings().phoneConnected )
        {
            var PhoneIconName = "";

            switch( System.getDeviceSettings().notificationCount )
            {
                case 0:
                    PhoneIconName = "phone_0";
                    break;
                case 1:
                    PhoneIconName = "phone_1";
                    break;
                case 2:
                    PhoneIconName = "phone_2";
                    break;
                default:
                    PhoneIconName = "phone_3";
                    break;
            }

            dc.drawBitmap(PhoneConnectAnchor[0] - Icons[PhoneIconName].getWidth() / 2,
                          PhoneConnectAnchor[1] - Icons[PhoneIconName].getHeight(),
                          Icons[PhoneIconName]);
        }

        // Data Icons + Text
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);

        var UsedDataOrder = DataOrder;
        if( System.getDeviceSettings().phoneConnected ) {
            UsedDataOrder = DataOrderPhoneConnected;
        }

        for(var i = 0; i < UsedDataOrder.size(); i++) {
            if( UsedDataOrder[i] == null )
            {
                continue;
            }

            var sym0X = DataAnchors[i][0];
            var sym0Y = DataAnchors[i][1];

            var icon = getDataIcon(UsedDataOrder[i]);
            if( icon != null)
            {
                dc.drawBitmap(sym0X - icon.getWidth() / 2,
                              sym0Y - icon.getHeight(),
                              icon);
            }

            dc.drawText(sym0X,
                        sym0Y,
                        MonoFont,
                        getDataString(UsedDataOrder[i]),
                        Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }

    function getLastLocation() as Position.Location{
        // Get current location and accuracy
        var Loc = Activity.getActivityInfo().currentLocation;
        var LocAcc = Activity.getActivityInfo().currentLocationAccuracy;

        // Test if location is valid and recent
        if(Loc != null && LocAcc >= Position.QUALITY_POOR)
        {
            // Save location
            Application.Storage.setValue("lastLocation", Loc.toGeoString(Position.GEO_DEG));
        }
        else
        {
            // Load location
            var lastLocFromStorage = Application.Storage.getValue("lastLocation");

            if( lastLocFromStorage != null )
            {
                Loc = Position.parse(lastLocFromStorage, Position.GEO_DEG);
            }
            else
            {
                Loc = null;

                // Debug Location
                // Loc = new Position.Location(
                // {
                //     :latitude => 0.0,
                //     :longitude => 0.0,
                //     :format => :degrees
                // });
            }
        }

        return Loc;
    }

    function getDataString(id as String) {
        switch(id)
        {
            case "hr":
                return getHeartRateString();
            case "bb":
                return getBodyBatteryString();
            case "steps":
                return getStepsString();
            case "sun":
                return getSunString();
            case "sunrise":
                return getSunEventString(true, false);
            case "sunset":
                return getSunEventString(false, false);
            case "sunriseAndSet":
                return getSunEventStringBoth();
            case "weather":
                return getWeatherString();
            default:
                return "-";
        }
    }

    function getDataIcon(id as String) {
        switch(id)
        {
            case "hr":
                return Icons["hr"];
            case "bb":
                return Icons["bb"];
            case "steps":
                return Icons["steps"];
            case "sunrise":
                return Icons["sunrise"];
            case "sunset":
                return Icons["sunset"];
            case "sunriseAndSet":
                return Icons["sunrise"];
            case "weather":
                return getWeatherIcon();
            default:
                return null;
        }
    }

    function getHeartRateString() {
        var HRString = "-";
        var HR = Activity.getActivityInfo().currentHeartRate;
        if( HR != null )
        {
            HRString = Lang.format("$1$", [HR]);
        }

        return HRString;
    }

    function getBodyBatteryString() {
        var BodyBatString = "-";
        if ((Toybox has :SensorHistory) && (Toybox.SensorHistory has :getBodyBatteryHistory)) {
            var BbIter = Toybox.SensorHistory.getBodyBatteryHistory({});
            // Default order of iterator is ORDER_NEWEST_FIRST
            BodyBatString = Lang.format("$1$", [BbIter.next().data.toNumber()]);
        }

        return BodyBatString;
    }

    function getStepsString() {
        var StepsString = "-";
        var Steps = ActivityMonitor.getInfo().steps;
        if( Steps != null )
        {
            if( Steps < 1000 )
            {
                StepsString = Lang.format("$1$", [Steps]);
            }
            else if( ( Steps < 10000 ) && ( Steps % 1000 >= 100 ) )
            {
                StepsString = Lang.format("$1$K$2$", [Steps / 1000, (Steps % 1000) / 100]);
            }
            else
            {
                StepsString = Lang.format("$1$K", [Steps / 1000]);
            }
        }

        return StepsString;
    }

    function getSunString() {
        var SunString = "-:-";
        var Loc = getLastLocation();
        if( Loc != null )
        {
            // Sunrise/Sunset from Loc
            var riseTime = Weather.getSunrise(Loc, Time.now() );
            var setTime = Weather.getSunset(Loc, Time.now() );

            var riseGreg = Time.Gregorian.info(riseTime, Time.FORMAT_SHORT);
            var setGreg = Time.Gregorian.info(setTime, Time.FORMAT_SHORT);

            SunString = Lang.format("$1$:$2$ ~ $3$:$4$",
                [riseGreg.hour.format("%02d"),
                riseGreg.min.format("%02d"),
                setGreg.hour.format("%02d"),
                setGreg.min.format("%02d")]);
        }

        return SunString;
    }

    function getSunEventString(riseEvent as Boolean, singleLine as Boolean) {
        var SunString = "-:-";
        var Loc = getLastLocation();

        if( Loc != null )
        {
            var now = Time.now();
            var sunToday = riseEvent ? Weather.getSunrise(Loc, now) : Weather.getSunset(Loc, now);

            var sunPrimaryGreg = null;
            var diffSeconds = 0;

            if( sunToday != null ) {
                // Sun event today is still ahead
                // -> Use today's event time and calc diff to yesterday
                if( sunToday.greaterThan(now) )
                {
                    var yesterday = now.subtract(new Time.Duration(Time.Gregorian.SECONDS_PER_DAY));
                    var sunYesterday = riseEvent ? Weather.getSunrise(Loc, yesterday) : Weather.getSunset(Loc, yesterday);
                    if( sunYesterday != null )
                    {
                        sunPrimaryGreg = Time.Gregorian.info(sunToday, Time.FORMAT_SHORT);
                        diffSeconds = sunToday.compare(sunYesterday.add(new Time.Duration(Time.Gregorian.SECONDS_PER_DAY)));
                    }
                }
                // Sun event today has already passed
                // -> Use tomorrow's event time and calc diff to today
                else
                {
                    var tomorrow = now.add(new Time.Duration(Time.Gregorian.SECONDS_PER_DAY));
                    var sunTomorrow = riseEvent ? Weather.getSunrise(Loc, tomorrow) : Weather.getSunset(Loc, tomorrow);
                    if( sunTomorrow != null )
                    {
                        sunPrimaryGreg = Time.Gregorian.info(sunTomorrow, Time.FORMAT_SHORT);
                        diffSeconds = sunTomorrow.compare(sunToday.add(new Time.Duration(Time.Gregorian.SECONDS_PER_DAY)));
                    }
                }

                if( sunPrimaryGreg != null )
                {
                    if( singleLine )
                    {
                        SunString = Lang.format("$1$:$2$",
                            [sunPrimaryGreg.hour,
                            sunPrimaryGreg.min.format("%02d")]);
                    }
                    else
                    {
                        SunString = Lang.format("$1$:$2$\n$3$$4$:$5$",
                            [sunPrimaryGreg.hour,
                            sunPrimaryGreg.min.format("%02d"),
                            diffSeconds < 0 ? "-" : "+",
                            (diffSeconds / 60).abs(),
                            (diffSeconds % 60).abs().format("%02d")]);
                    }
                }
            }
        }

        return SunString;
    }

    function getSunEventStringBoth() {
        var SunString = "-";

        SunString = Lang.format("$1$\n$2$",
            [getSunEventString(true, true),
            getSunEventString(false, true)]);

        return SunString;
    }

    function getWeatherString() {
        var WeatherString = "-";
        var Conditions = Weather.getCurrentConditions();

        if( Conditions != null )
        {
            // ToDo: Display wind bearing in $2$
            WeatherString = Lang.format("$1$°C\n$2$$3$",
                [Math.round(Conditions.temperature).format("%01d"),
                "Bearing",
                Math.round(Conditions.windSpeed * 3.6).format("%01d")]);
        }

        return WeatherString;
    }

    function getWeatherIcon() {
        var Condition = Weather.CONDITION_UNKNOWN;

        var Conditions = Weather.getCurrentConditions();
        if( Conditions != null )
        {
            Condition = Conditions.condition;
        }

        switch(Condition)
        {
            case Weather.CONDITION_CLEAR:
                return null;
            case Weather.CONDITION_PARTLY_CLOUDY:
                return null;
            case Weather.CONDITION_MOSTLY_CLOUDY:
                return null;
            case Weather.CONDITION_RAIN:
                return null;
            case Weather.CONDITION_SNOW:
                return null;
            case Weather.CONDITION_WINDY:
                return null;
            case Weather.CONDITION_THUNDERSTORMS:
                return null;
            case Weather.CONDITION_WINTRY_MIX:
                return null;
            case Weather.CONDITION_FOG:
                return null;
            case Weather.CONDITION_HAZY:
                return null;
            case Weather.CONDITION_HAIL:
                return null;
            case Weather.CONDITION_SCATTERED_SHOWERS:
                return null;
            case Weather.CONDITION_SCATTERED_THUNDERSTORMS:
                return null;
            case Weather.CONDITION_UNKNOWN_PRECIPITATION:
                return null;
            case Weather.CONDITION_LIGHT_RAIN:
                return null;
            case Weather.CONDITION_HEAVY_RAIN:
                return null;
            case Weather.CONDITION_LIGHT_SNOW:
                return null;
            case Weather.CONDITION_HEAVY_SNOW:
                return null;
            case Weather.CONDITION_LIGHT_RAIN_SNOW:
                return null;
            case Weather.CONDITION_HEAVY_RAIN_SNOW:
                return null;
            case Weather.CONDITION_CLOUDY:
                return null;
            case Weather.CONDITION_RAIN_SNOW:
                return null;
            case Weather.CONDITION_PARTLY_CLEAR:
                return null;
            case Weather.CONDITION_MOSTLY_CLEAR:
                return null;
            case Weather.CONDITION_LIGHT_SHOWERS:
                return null;
            case Weather.CONDITION_SHOWERS:
                return null;
            case Weather.CONDITION_HEAVY_SHOWERS:
                return null;
            case Weather.CONDITION_CHANCE_OF_SHOWERS:
                return null;
            case Weather.CONDITION_CHANCE_OF_THUNDERSTORMS:
                return null;
            case Weather.CONDITION_MIST:
                return null;
            case Weather.CONDITION_DUST:
                return null;
            case Weather.CONDITION_DRIZZLE:
                return null;
            case Weather.CONDITION_TORNADO:
                return null;
            case Weather.CONDITION_SMOKE:
                return null;
            case Weather.CONDITION_ICE:
                return null;
            case Weather.CONDITION_SAND:
                return null;
            case Weather.CONDITION_SQUALL:
                return null;
            case Weather.CONDITION_SANDSTORM:
                return null;
            case Weather.CONDITION_VOLCANIC_ASH:
                return null;
            case Weather.CONDITION_HAZE:
                return null;
            case Weather.CONDITION_FAIR:
                return null;
            case Weather.CONDITION_HURRICANE:
                return null;
            case Weather.CONDITION_TROPICAL_STORM:
                return null;
            case Weather.CONDITION_CHANCE_OF_SNOW:
                return null;
            case Weather.CONDITION_CHANCE_OF_RAIN_SNOW:
                return null;
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN:
                return null;
            case Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW:
                return null;
            case Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN_SNOW:
                return null;
            case Weather.CONDITION_FLURRIES:
                return null;
            case Weather.CONDITION_FREEZING_RAIN:
                return null;
            case Weather.CONDITION_SLEET:
                return null;
            case Weather.CONDITION_ICE_SNOW:
                return null;
            case Weather.CONDITION_THIN_CLOUDS:
                return null;
            case Weather.CONDITION_UNKNOWN:
                return null;
            default:
                return null;
        }
    }
}
