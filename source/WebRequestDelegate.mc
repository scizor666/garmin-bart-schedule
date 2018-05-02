//
// Copyright 2016 by Garmin Ltd. or its subsidiaries.
// Subject to Garmin SDK License Agreement and Wearables
// Application Developer Agreement.
//

using Toybox.Communications as Comm;
using Toybox.WatchUi as Ui;

class WebRequestDelegate extends Ui.BehaviorDelegate {
    var notify;

    // Handle menu button press
    function onMenu() {
        makeRequest();
        return true;
    }

    function onSelect() {
        makeRequest();
        return true;
    }

    function makeRequest() {
        notify.invoke("Executing\nRequest");

        Comm.makeWebRequest(
            "https://api.bart.gov/api/etd.aspx?cmd=etd&orig=phil&key=MW9S-E7SL-26DU-VV8V&json=y",
            {
            },
            {
                :method => Comm.HTTP_REQUEST_METHOD_GET,
                :responseType => Comm.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceive)
        );
    }

    // Set up the callback to the view
    function initialize(handler) {
        Ui.BehaviorDelegate.initialize();
        notify = handler;
    }

    // Receive the data from the web request
    function onReceive(responseCode, data) {
        if (responseCode == 200) {
        	var destinations = data.get("root").get("station")[0].get("etd");
        	var message = "";
    		for (var i = 0; i < destinations.size(); i++) {
    			var destination = destinations[i];
    			var minutes = destination.get("estimate")[0].get("minutes");
    			message += destination.get("destination") + ": " + minutes + "\n";
    		}
        	notify.invoke(message.length() > 0 ? message : "No destinations available!");
        } else {
            notify.invoke("Failed to load\nError: " + responseCode.toString());
        }
    }
}