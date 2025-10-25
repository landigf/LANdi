#ifndef LANDI_SIMULATOR_HPP
#define LANDI_SIMULATOR_HPP

#include "Event.hpp"
#include <queue>
/**
 * @class Simulator
 * @brief Menages the main simulation loop.
 */
class Simulator {
public:
    Simulator();

    void run();

    /**
     * @brief Adds a new event to the queue
     * @param event The Event object to be scheduled.
     */
    void addEvent(const Event& e);

private:
    std::priority_queue<Event> queue_; ///< Priority queue ordered by event time
    double now_; ///< Current simulated time.
};

#endif