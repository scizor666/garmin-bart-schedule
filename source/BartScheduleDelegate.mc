using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;
using Toybox.Math as Math;
using Toybox.Timer;
using Toybox.System;

class BartScheduleDelegate extends Ui.BehaviorDelegate {

    const BART_API_BASE_URL = "https://api.bart.gov/api";
    const BART_API_DEFAULT_PARAMS = "key=MW9S-E7SL-26DU-VV8V&json=y";
    const BART_API_DEFAULT_OPTIONS = { :method => Comm.HTTP_REQUEST_METHOD_GET,
                                       :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON };

   const APP_CONNECTION_REQUIRED = "App Connection\nRequired";

    var notify;
    var stations;
    var loading = false;
    var locationUpdated = false;
    var station;
    var viewer;

    function initialize(handler) {
        Ui.BehaviorDelegate.initialize();
        notify = handler;
        stations = Ui.loadResource(Rez.JsonData.stations);
        updateAll();
    }

    function onMenu() {
        return false;
    }

    function onSelect() {
        if (!loading) {
            if (viewer != null) {
                viewer.stop();
                viewer = null;
            }
        	updateAll();
    	}
        return true;
    }

    function updateAll() {
        if (!System.getDeviceSettings().phoneConnected) {
            notify.invoke(APP_CONNECTION_REQUIRED);
            return;
        }
        loading = true;

        if (station == null || !locationUpdated) {
            notify.invoke("Waiting for\nGPS...");
            var query = new PositionQuery();
            query.requestPosition(station == null ? Position.QUALITY_LAST_KNOWN : Position.QUALITY_USABLE, null, method(:onPositionDefined));
        } else {
            recieveStationDestinations(station);
        }
    }

    function onPositionDefined(info) {
        if (station != null) {
            locationUpdated = true;
        }
        var position = info.position.toDegrees();
        station = closestStation(position);
        if (locationUpdated) {
            stations = null; // stations not needed anymore
        }
        recieveStationDestinations(station);
    }

    function closestStation(position) {
        var closestStation = stations[0]["abbr"];
        var closestDistance = calculateDistance(position, [stations[0]["gtfs_latitude"], stations[0]["gtfs_longitude"]]);
        for (var i = 1; i < stations.size(); i++) {
            var currentDistance = calculateDistance(position, [stations[i]["gtfs_latitude"], stations[i]["gtfs_longitude"]]);
            if (currentDistance < closestDistance) {
                closestStation = stations[i]["abbr"];
                closestDistance = currentDistance;
            }
        }
        return closestStation;
    }

    function calculateDistance(from, to) {
        return Math.sqrt(Math.pow(to[0] - from[0], 2) + Math.pow(to[1] - from[1], 2));
    }

    function recieveStationDestinations(station) {
        notify.invoke("BART destinations\nare loading...");
        Comm.makeWebRequest(
            Lang.format("$1$/etd.aspx?cmd=etd&orig=$2$&$3$", [BART_API_BASE_URL, station, BART_API_DEFAULT_PARAMS]),
            {},
            BART_API_DEFAULT_OPTIONS,
            method(:onReceiveStationSchedule)
        );
    }

    function onReceiveStationSchedule(responseCode, data) {
        loading = false;
        switch (responseCode) {
            case 200: {
                updateDestinations(data["root"]["station"][0]);
                break;
            }
            case -300: {
                notify.invoke("Network\nNot Available.\nTry Again");
                break;
            }
            case -2: {
                notify.invoke("Check Bluetooth\nConnection");
                break;
            }
            case -104: {
                notify.invoke(APP_CONNECTION_REQUIRED);
                break;
            }
            default: {
                notify.invoke("Failed to Load\nError: " + responseCode.toString());
                break;
            }
        }
    }

    function updateDestinations(stationData) {
        try {
            viewer = new DestinationViewer(stationData["name"], destinationsFromStationData(stationData), notify);
            viewer.view();
        } catch (ex) {
            notify.invoke("Server Error.\nTry Later");
        }
    }

    hidden function destinationsFromStationData(stationData) {
        var destinations = [];
        if (stationData["etd"] != null) {
            for (var i = 0; i < stationData["etd"].size(); i++) {
                var minutes = [];
                for(var j = 0; j < stationData["etd"][i]["estimate"].size(); j++) {
                    minutes.add(stationData["etd"][i]["estimate"][j]["minutes"]);
                }
                destinations.add({:name => stationData["etd"][i]["destination"], :minutes => minutes});
            }
        }
        return destinations;
    }
}