#!/bin/bash
docker kill web
docker rm web
docker build -t django .
docker run --name web -d -P -v $(pwd)/example_app:/code django
docker ps -a |grep django



