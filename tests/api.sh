http --verbose --pretty format GET 127.0.0.1:8080/api/music/songs/_aggrs/group?avars={"key":'$albumartist'}

http --verbose --pretty format GET 127.0.0.1:8080/api/music/songs/_aggrs/group2?avars={"key":'$album',"matchQuery":{"albumartist":"Young Thug"}}
