# Youtube Dashboard

## Project objective
Build a youtube dashboard which can give insights about channels, videos & comments.

Below are some sample questions:-

      1. What are the names of all the videos and their corresponding channels?

      2. Which channels have the most number of videos, and how many videos do they have?
      
      3. What are the top 10 most viewed videos and their respective channels?
      
      4. How many comments were made on each video, and what are their corresponding video names?
      
      5. Which videos have the highest number of likes, and what are their corresponding channel names?
      
      6. What is the total number of likes and dislikes for each video, and what are their corresponding video names?
      
      7. What is the total number of views for each channel, and what are their corresponding channel names?
      
      8. What are the names of all the channels that have published videos in the year 2022?
      
      9. What is the average duration of all videos in each channel, and what are their corresponding channel names?
      
      10.Which videos have the highest number of comments, and what are their corresponding channel names?


## Tech and language
1.Azure VM for linux webserver

2.Mongo db, postgreSQL, 

3.lang - python, javascript, html, css

4.pip install >> pip install -r requirements.txt


## Pre-steps

### Platform-setup

1.Create a Azure VM with HTTPS/HTTP enabled

2.Install mongodb

3.Install postgresSQL

4.Install python, javascript




### Configuration-setup
1.youtube channels config

2.credentials

    a.mongodb

    b.webserver ssh_host, ssh_user & ssh_key

    c.youtube api key

        google developer console --> create new project --> Enable "youtube data API 3" api --> create API key at credentials

    d.postgresSQL


### Workflow (This will prepare the backend data to be ready)
1. Extract data and load it into mongoDB
2. Extract mongodb data
3. Clean the data
4. Process the semi structured data into structured data 
5. load it into PostgreSQL


Finally, the youtube dashboard is ready at the website!!!

