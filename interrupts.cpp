/**
 *
 * @file interrupts.cpp
 * @author Sasisekhar Govind
 *
 */

#include<interrupts.hpp>

int main(int argc, char** argv) {

    //vectors is a C++ std::vector of strings that contain the address of the ISR
    //delays  is a C++ std::vector of ints that contain the delays of each device
    //the index of these elemens is the device number, starting from 0
    auto [vectors, delays] = parse_args(argc, argv);
    std::ifstream input_file(argv[1]);

    std::string trace;      //!< string to store single line of trace file
    std::string execution;  //!< string to accumulate the execution output

    /******************ADD YOUR VARIABLES HERE*************************/
    long long current_time = 0;
    long long CTX_SAVE_MS  = 20;
    if (const char* e = std::getenv("CTX_SAVE_MS")) CTX_SAVE_MS = std::stoll(e);

    long long ADDR_BYTES   = 2;   // 2 or 4 (address width for vector/PC)
    if (const char* e = std::getenv("ADDR_BYTES")) ADDR_BYTES = std::stoll(e);

    long long CPU_SPEEDUP  = 1;   // 1=no change, 2=2x faster CPU, 4=4x faster, etc.
    if (const char* e = std::getenv("CPU_SPEEDUP")) CPU_SPEEDUP = std::stoll(e);

    auto log_line = [&](long long duration, const std::string& what) {
        execution += std::to_string(current_time) + ", " +
                    std::to_string(duration) + ", " + what + "\n";
        current_time += duration;
    };
    /******************************************************************/

    while (std::getline(input_file, trace)) {
        auto [activity, duration_intr] = parse_trace(trace);

    /******************ADD YOUR SIMULATION CODE HERE*************************/
        if (activity == "CPU") {
            long long d = duration_intr;
            if (CPU_SPEEDUP > 1) d = (d + CPU_SPEEDUP - 1) / CPU_SPEEDUP; // ceil divide
            log_line(d, "CPU burst");
        } else if (activity == "SYSCALL" || activity == "END_IO") {
            int dev = duration_intr;
            long long dev_delay = 0;
            if (dev >= 0 && dev < (int)delays.size()) dev_delay = delays[dev];

            auto [pre, t_after] = intr_boilerplate((int)current_time, dev, (int)CTX_SAVE_MS, vectors);
            execution += pre;
            current_time = t_after;

            long long overhead = CTX_SAVE_MS + 4;
            long long body_ms = std::max(0LL, dev_delay - overhead);
            if (const char* e = std::getenv("ISR_BODY_MS")) body_ms = std::stoll(e);

            if (ADDR_BYTES > 2) {
                long long extra = (ADDR_BYTES - 2); // +1 ms per extra byte for find+load combined
                log_line(extra, "memory access (wider address)");
            }

            const std::string body_label =
                (activity == "END_IO") ? "store information in memory"
                                    : "call device driver";
            if (body_ms > 0) log_line(body_ms, body_label);

            log_line(1, "IRET");
        }
    /************************************************************************/
    }


    input_file.close();

    write_output(execution);

    return 0;
}
