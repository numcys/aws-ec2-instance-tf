#!/bin/bash

# Install convox CLI tool
curl -L https://github.com/convox/convox/releases/latest/download/convox-linux -o /tmp/convox
sudo mv /tmp/convox /usr/local/bin/convox
sudo chmod 755 /usr/local/bin/convox

convox login console3-staging1.convox.com -t 6131582ee6d94f61904c3e36d1ad6dcd

# Set the command to run
command="convox runtimes naman-stg"

num_runs=10
# Initialize an empty array for execution times
execution_times=()

index_html="index.html"
touch "$index_html"

data_html="data.html"
touch "$data_html"

# Loop for the desired number of runs
for i in $(seq 1 $num_runs); do
  # Capture the start time
  start_time=$(date +%s.%N)


  # Run the command
  $command

  # Capture the end time
  end_time=$(date +%s.%N)

  output=$(eval "$command")
  echo "$output" >> "$data_html"

  # Calculate the execution time
  execution_time=$(echo "$end_time - $start_time" | bc)

  # Add the execution time to the array
  execution_times+=($execution_time)

  # Print the execution time for this run
  printf "Run %d: Execution time: %.3f seconds\n" "$i" "$execution_time" >> "$index_html"

done

# Calculate and print the average execution time
total_time=$(echo "${execution_times[@]}" | tr ' ' '+' | bc)
average_time=$(echo "scale=3; $total_time / $num_runs" | bc)
echo "Average execution time: $average_time seconds" >> "$index_html"

nohup busybox httpd -f -p 8080 &
