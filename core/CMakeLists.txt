cmake_minimum_required(VERSION 3.20)
project(LANdiCore)

# Find required packages
find_package(fmt CONFIG REQUIRED)

# Add source files
add_executable(landi_core 
    main.cpp
    src/Event.cpp
    src/Logger.cpp
    src/Queue.cpp
    src/Simulator.cpp
)

# Include directories
target_include_directories(landi_core PRIVATE include)

# Link libraries
target_link_libraries(landi_core PRIVATE fmt::fmt)