#include "Simulator.hpp"
#include <fmt/core.h>

Simulator::Simulator() : now_(0.0) {}

void Simulator::addEvent(const Event& e){
    queue_.push(e);
}

void Simulator::run(){
    while(!queue_.empty()){
        Event e = queue_.top(); queue_.pop();

        now_ = e.time;

        fmt::print("time: {}, type: {}\n", e.time, e.type);
    }
}