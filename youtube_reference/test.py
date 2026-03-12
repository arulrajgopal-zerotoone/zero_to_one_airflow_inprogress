
from config import *
from utility import *
from datetime import datetime
import pandas as pd

channel_playlist_dict = {'UCKTWY-rVwUqCxrVmPOlJyjA': 'UUKTWY-rVwUqCxrVmPOlJyjA',}


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


video_response_list = get_video_header_raw(channel_playlist_dict)
print(video_response_list[0])







