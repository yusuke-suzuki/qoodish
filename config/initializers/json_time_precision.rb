# The timestamp columns keep microseconds, and a feed cursor is a timestamp
# handed back by the client. Emitting only milliseconds would make the
# cursor land between rows created in the same millisecond.
ActiveSupport::JSON::Encoding.time_precision = 6
