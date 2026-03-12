import json
from integrate_utils import *
from old.old_utility import *
from config import *



channel_details_lst = get_channel_details(channel_id_dict)

for json in channel_details_lst:
    load_dyanmo_db("channel_details_tbl","channel_id",json)


for channel in channel_details_lst:
    channel_id = channel["channel_id"]
    ply_lst_id = channel["upload_plylst_id"]

    video_id_lst= get_videos_list(ply_lst_id)
    video_details_lst = get_video_details(video_id_lst)


    for json in video_details_lst:
        json["channel_id"] = channel_id
        json["playlist_id"] = ply_lst_id

        load_dyanmo_db("video_details_tbl","video_id",json)


print("data fetchted from api and loaded into dynamodb successfully!")


channel_df = fetch_dynamo_data_into_pd_dataframe("channel_details_tbl")
channel_df.to_sql('youtube_channels', sqlalchemy_engine, if_exists='append', index=False)

video_df = fetch_dynamo_data_into_pd_dataframe("video_details_tbl")
video_df.to_sql('youtube_videos', sqlalchemy_engine, if_exists='append', index=False)

print("data loaded into postgresql successfully!")
