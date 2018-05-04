using Toybox.Position as Position;

class PositionQuery {
    var accuracy;
    var moment;
    var callback;

    function requestPosition(accuracy, moment, callback) {
        self.accuracy = accuracy;
        self.moment = moment;
        self.callback = callback;

        Position.enableLocationEvents(Position.LOCATION_CONTINUOUS, method(:onPosition));
    }

    function onPosition(info) {
        if (info.accuracy != null && info.accuracy >= self.accuracy) {

            if (self.moment == null || !self.moment.greaterThan(info.when)) {
                Position.enableLocationEvents(Position.LOCATION_DISABLE, null);

                self.callback.invoke(info);
            }
        }
    }
}