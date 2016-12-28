package Mojo::Weixin::Plugin::Weather;
our $PRIORITY=91;

sub call
{
	my $client=shift;
    my $callback=sub
    {
    	my ($client,$msg)=@_;
        return if $msg->class eq "send" and $msg->from eq "code";
        return if not $msg->allow_plugin;
    	if($msg->content=~/^(\S+)天气$/)
    	{
            $msg->allow_plugin(0);
    		my $city=$1;
    		my $weatherurl='http://apix.sinaapp.com/weather/?&city='. $client->url_escape($city);
    		$client->http_get($weatherurl,sub
    		                              {  
				                              	my $content=shift;
				                              	if(not defined $content){$msg->reply("api接口不可用，perlcoder公众号留言")}
				                              	
				                              	elsif($content=~/没有该城市/)
				                              	{
				                              		$msg->reply("没有该城市：  $city市,格式：上海天气");
				                              	}
				                              	elsif($content=~/[{.*}]/g)				                              	
				                              	{
                                                    my $json = $client->from_json($content);
                                                    if(not defined $json){
                                                        $client->debug("[ " . __PACKAGE__ . " ]json数据解析失败");
                                                        return;
                                                    }
                                                    my $result = join "\n",map {$_->{Title}} @{$json};
							$result = $result;
				                              		$msg->reply($result);
				                              	}
					                        
                                                 			
    			
    			
    			                           }
    			              );
    		
    		
    		
    	};
    	#http://apix.sinaapp.com/weather/?&city=%E6%97%A0%E9%94%A1
    	
        
    };
    
    $client->on(receive_message=>$callback,send_message=>$callback);  
    
	
	
	
	
}
1;
