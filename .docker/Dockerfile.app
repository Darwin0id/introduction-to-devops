# Use an official Python runtime
FROM python:3.7-slim

# Set the working directory in the container to /app
WORKDIR /app

# Update all packages in the image
RUN apt-get update && apt-get upgrade -y

# Add the current directory contents into the container at /app
ADD bin/app /app

# Make port 5000 available to the world outside this container
EXPOSE 5000

# Run the binary
CMD ["./app"]
