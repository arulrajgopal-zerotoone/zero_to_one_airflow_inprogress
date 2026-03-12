from utility import *

channel_details_lst, channel_plylst_dic = extract_channel_details(channel_id_dict)
print("channels details extracted successfully!")

for response in channel_details_lst:
    load_dyanmo_db("channel_raw","channel_id",response)
print("channels details loaded into dynamoDB successfully!")


video_response_list = get_video_header_raw(channel_plylst_dic)
print("video header extracted successfully!")


for response in video_response_list:
    load_dyanmo_db("video_details_raw_tbl","video_id",response)
print("channels details loaded into dynamoDB successfully!")



