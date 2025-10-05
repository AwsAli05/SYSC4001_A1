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
        long long CTX_SAVE_MS  = 10;
        auto log_line = [&](long long duration, const std::string& what) {
            execution += std::to_string(current_time) + ", " +
                        std::to_string(duration) + ", " + what + "\n";
            current_time += duration;
        };
    /******************************************************************/

    //parse each line of the input trace file
    while(std::getline(input_file, trace)) {
        auto [activity, duration_intr] = parse_trace(trace);

        /******************ADD YOUR SIMULATION CODE HERE*************************/

        if (activity == "CPU") {
            log_line(duration_intr, "CPU burst");
        } 
        else if (activity == "SYSCALL" || activity == "END_IO") {
            int dev = duration_intr;
            long long dev_delay = 0;
            if (dev >= 0 && dev < (int)delays.size()) dev_delay = delays[dev];

            log_line(1, "switch to kernel mode");
            log_line(CTX_SAVE_MS, "context saved");

            long long mem_pos = (long long)dev * 2LL;
            log_line(1, "find vector " + std::to_string(dev) +
                            " in memory position " + std::to_string(mem_pos));
            log_line(1, "obtain ISR address");
            const std::string body_label =
                (activity == "END_IO") ? "store information in memory"
                                    : "call device driver";

            long long body_time = dev_delay - 14;
            if (body_time < 0) body_time = 0;

            log_line(body_time, body_label);

            log_line(1, "IRET");
        }
    }

        /************************************************************************/


    input_file.close();

    write_output(execution);

    return 0;
}
