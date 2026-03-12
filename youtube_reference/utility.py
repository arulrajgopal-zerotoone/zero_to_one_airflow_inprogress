from config import *
from utility import *
from datetime import datetime
import pandas as pd


def load_dyanmo_db(table_name,primary_key,value):
    table = dynamodb.Table(table_name)
    table.put_item(Item=value)
    record_id = value[primary_key]
    print(f"{record_id} record written into {table_name} successfully!!!")


def fetch_dynamo_data_into_pd_dataframe(table_name):
    table = dynamodb.Table(table_name)

    response = table.scan()
    data = response.get('Items', [])

    # Handle pagination
    while 'LastEvaluatedKey' in response:
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        data.extend(response.get('Items', []))

    df = pd.DataFrame(data)

    return df


def extract_channel_details(channel_id_dict):
    current_date = int(datetime.now().strftime("%Y%m%d%H"))
    channel_details_lst = []
    channel_plylst_dic = {}

    for channel in channel_id_dict.values():
        request =youtube.channels().list(part="snippet,contentDetails,statistics", id=channel)
        response = request.execute()
        current_time = str(datetime.now())
        response["channel_id"] = channel
        response["load_dt"] = current_date
        response["updated_time"] = current_time


        channel_details_lst.append(response)
        channel_plylst_dic[channel] = response['items'][0]['contentDetails']['relatedPlaylists']['uploads']


    return channel_details_lst, channel_plylst_dic



def get_video_header(playlist_id):
  video_response_lst = []

  request = youtube.playlistItems().list(part='contentDetails',playlistId = playlist_id)
  response = request.execute()

  for i in range(len(response['items'])):
    video_response_lst.append(response)

    

  next_page_token = response.get('nextPageToken')
  more_pages = True

  while more_pages:
    if next_page_token is None:
      more_pages = False
    else:
        request = youtube.playlistItems().list(part='contentDetails',playlistId = playlist_id,maxResults = 50, pageToken = next_page_token)
        response = request.execute()

        for i in range(len(response['items'])):
          video_response_lst.append(response)

        next_page_token = response.get('nextPageToken')

  return video_response_lst


def get_video_header_raw(channel_playlist_dict):
    current_date = int(datetime.now().strftime("%Y%m%d%H"))
    video_response_list = []
    for playlst in channel_playlist_dict.values():
        
        video_response_lst = get_video_header(playlst)

        for i in range(len(video_response_lst)):
            response = video_response_lst[i]["items"]
        
            for j in range(len(response)):
                temp_dic = {}
                temp_dic["video_id"] = response[j]["contentDetails"]["videoId"]
                temp_dic["response"] = response[j]
                current_time = str(datetime.now())
                temp_dic["playlist_id"] = playlst
                temp_dic["load_dt"] = current_date
                temp_dic["updated_time"] = current_time
                video_response_list.append(temp_dic)
    
    return video_response_list



# def get_video_all(channel_plylst_dic):
#     current_date = int(datetime.now().strftime("%Y%m%d%H"))
#     video_header_lst = []
#     video_details_lst = []
   
#     for playlist_id in channel_plylst_dic.values():
#         video_header_dict = get_video_header(playlist_id)

#         for video_id, video_response in video_header_dict.items():
           
#             current_time = str(datetime.now())
#             video_response["playlist_id"] = playlist_id
#             video_response["video_id"] = video_id
#             video_response["load_dt"] = current_date
#             video_response["updated_time"] = current_time
#             video_header_lst.append(video_response)

#         # video_id_list = list(video_header_dict.keys())
#         # for video in range(0, len(video_id_list), 50):
#         #     request = youtube.videos().list(part="snippet,contentDetails,statistics",id=','.join(video_id_list[video:video+50]))
#         #     response = request.execute()
#         #     current_time = str(datetime.now())
#         #     response["playlist_id"] = playlist_id
#         #     response["video_id"] =video
#         #     response["load_dt"] = current_date
#         #     response["updated_time"] = current_time
#         #     video_details_lst.append(response)
        
#     return video_header_lst,video_details_lst