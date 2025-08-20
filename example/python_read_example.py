from collections import namedtuple
import struct
import gzip

RobotState = namedtuple('RobotState', ['protocol_version', 'id', 'positionX', 'positionY', 'isActive', 'name', 'coordinates', 'commandLog', 'point'])
Point = namedtuple('Point', ['x', 'y'])

def read_robot_state(filename):
    compressed = filename.endswith('.gz')
    try:
        data = gzip.open(filename, 'rb').read() if compressed else open(filename, 'rb').read()
        print(f"File size: {len(data)} bytes")
        print(f"First 4 bytes: {list(data[:4])}")
        
        offset = 0
        def unpack(fmt, size):
            nonlocal offset
            if offset + size > len(data):
                raise ValueError(f"Buffer too short: need {offset + size} bytes, got {len(data)}")
            result = struct.unpack_from('<' + fmt, data, offset)[0]
            offset += size
            return result

        version = unpack('i', 4)
        if version != 1:
            raise ValueError(f"Versi protokol tidak didukung: {version}")

        id_val = unpack('i', 4)
        pos_x = unpack('d', 8)
        pos_y = unpack('d', 8)
        active = unpack('B', 1) == 1
        name = None
        if unpack('B', 1):
            name_len = unpack('i', 4)
            name = data[offset:offset + name_len * 2].decode('utf-16-le')
            offset += name_len * 2

        coord_len = unpack('i', 4)
        coords = [unpack('d', 8) for _ in range(coord_len)]

        cmd_len = unpack('i', 4)
        cmds = []
        for _ in range(cmd_len):
            if unpack('B', 1):
                cmd_len = unpack('i', 4)
                # cmd = data[offset:offset + cmd_len * 2].decode('utf-16-le')
                # offset += cmd_len * 2
                cmd = data[offset:offset + cmd_len].decode('utf-8') 
                offset += cmd_len
                cmds.append(cmd)
            else:
                cmds.append(None)

        if offset + 8 > len(data):
            raise ValueError(f"Buffer terpotong untuk Point: perlu {offset + 8} bytes, got {len(data)}")
        point_x = unpack('i', 4)
        point_y = unpack('i', 4)

        return RobotState(
            protocol_version=version,
            id=id_val,
            positionX=pos_x,
            positionY=pos_y,
            isActive=active,
            name=name,
            coordinates=coords,
            commandLog=cmds,
            point=Point(point_x, point_y)
        )
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    print("-"* 40)
    print("Reading robot state from file with python...")
    filename = 'robot_state.gz'  # atau 'robot_state.bin'
    result = read_robot_state(filename)
    if result:
        print(result)