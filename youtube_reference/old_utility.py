from googleapiclient.discovery import build
from config import *


youtube =  build("youtube","v3",developerKey=youtube_api_key)



def get_channel_details(channel_id_dict):
  all_data = []
  channel_details_lst = []

  for i,j in channel_id_dict.items():
    request =youtube.channels().list(part="snippet,contentDetails,statistics", id=j)
    response = request.execute()
    all_data.append(response)
    data = dict(
              channel_id = j,
              channel_name = response['items'][0]['snippet']['title'],
              subscribers = response['items'][0]['statistics']['subscriberCount'],
              views = response['items'][0]['statistics']['viewCount'],
              videos = response['items'][0]['statistics']['videoCount'],
              upload_plylst_id = response['items'][0]['contentDetails']['relatedPlaylists']['uploads']
              )
    channel_details_lst.append(data)

  return channel_details_lst



def get_video_header(playlist_id):
  video_header_dict = {}

  request = youtube.playlistItems().list(part='contentDetails',playlistId = playlist_id)
  response = request.execute()

  for i in range(len(response['items'])):
    video_header_dict[response['items'][i]['contentDetails']['videoId']] = response

  next_page_token = response.get('nextPageToken')
  more_pages = True

  while more_pages:
    if next_page_token is None:
      more_pages = False
    else:
        request = youtube.playlistItems().list(part='contentDetails',playlistId = playlist_id,maxResults = 50, pageToken = next_page_token)
        response = request.execute()

        for i in range(len(response['items'])):
          video_header_dict[response['items'][i]['contentDetails']['videoId']] = response

        next_page_token = response.get('nextPageToken')

  return video_header_dict


def get_video_details(video_id_lst):
  #dislikecount not available in the API
  all_video_stats = []

  for i in range(0, len(video_id_lst), 50):
    request = youtube.videos().list(part="snippet,contentDetails,statistics",id=','.join(video_id_lst[i:i+50]))
    response = request.execute()

    for video in response['items']:
      video_id = video['id']
      title = video['snippet']['title']
      published_date = video['snippet']['publishedAt']
      try: 
        views = video['statistics']['viewCount']
      except KeyError:
        views = 0
      try:
        likes = video['statistics']['likeCount']
      except KeyError:
        likes = 0
      try:
        comments = video['statistics']['commentCount']
      except KeyError:
        comments = 0
      duration = video['contentDetails']['duration']

      video_stats = dict(
                      video_id = video_id,
                      title = title,
                      published_date = published_date,
                      views = views,
                      likes = likes,
                      comments = comments,
                      duration = duration
                      )
      
      all_video_stats.append(video_stats)
      

  return all_video_stats




def get_popular_comments(video_id):
  popular_comments_lst = []

  request = youtube.commentThreads().list(part="snippet,replies", maxResults=100,order="relevance",videoId=video_id)
  response = request.execute()

  for video in response['items']:
      video_stats = dict(
                      VideoId = video['snippet']['videoId'],
                      Author = video['snippet']['topLevelComment']['snippet']['authorDisplayName'],
                      Comment = video['snippet']['topLevelComment']['snippet']['textDisplay'],
                      CommentId = video['snippet']['topLevelComment']['id'],
                      CommentLike = video['snippet']['topLevelComment']['snippet']['likeCount'],
                      Replies = video['snippet']['totalReplyCount'],
                      PublishedAt = video['snippet']['topLevelComment']['snippet']['publishedAt'],
                      UpdatedAt = video['snippet']['topLevelComment']['snippet']['updatedAt']
                      )
      popular_comments_lst.append(video_stats)

  return popular_comments_lst