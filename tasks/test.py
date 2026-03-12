import datetime

# Get current date and time
now = datetime.datetime.now()

# Print message with timestamp
print("Hello, World! Current UTC time is:", now.strftime("%Y-%m-%d %H:%M:%S"))