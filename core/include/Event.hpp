#ifndef LANDI_EVENT_HPP
#define LANDI_EVENT_HPP

#include <string>
#include <nlohmann/json.hpp>

/**
 * @brief Represents a single simulation event.
 * 
 * Each event has:
 *  - time: simulated time (double)
 *  - type: event category, like "HttpRequestCreated" or "PacketArrived"
 *  - data: key/value payload stored as JSON
 *
 * Example:
 * {
 *   "time": 12.5,
 *   "type": "PacketRecieved",
 *   "data": { "src": "A", "dst": "B" }
 * }
 */
struct Event {
    double time;             ///< Simulated time when the event occurs
    std::string type;        ///< Event category or name
    nlohmann::json data;     ///< Additional event data

    bool operator<(const Event& other) const {
        return time > other.time;  // reversed for min-heap behavior
    }
};

#endif