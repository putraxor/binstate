dart binstate_example.dart compress
python3 python_read_example.py  
gunzip -c robot_state.gz | wc -c 
gunzip -c robot_state.gz > robot_state.bin
xxd -s -8 -l 8 robot_state.bin