-module(servere).
-export([new/0,relay/1,spot_user/1,registering/2,disconnectTheUser/1,filter_tweets/1,tweet_ByUser/1,find_follow/1,increase_Follower/2,find_subscribers/1,increase_Following/2,tweet/2,package_for_subs/2,
    find_mentions_hash/3,find_mentions_hash/4,update_tags/2,subscriptions/1,generate_data/2,tweetContaininghashtag/2,tweetContainingMention/1,begin_server/0]).

new() ->
  spawn(fun() -> relay(0) end).

relay(N) ->
  receive
    {userRegistration,UserId,Pid} ->
       registering(UserId,Pid),
       Pid ! {registered},
      relay(N + 1);

    {tweet,Tweet,UserId} ->
        tweet(Tweet,UserId),
        relay(N+1);

    {subscriptions,UserId} ->
        subscriptions(UserId),
        relay(N+1);

    {tweetContaininghashtag,HashTag,UserId} ->
        tweetContaininghashtag(HashTag,UserId),
        relay(N+1);

    {tweetContainingMention,UserId} ->
        tweetContainingMention(UserId),
        relay(N+1);
        
    {tweetByUser,UserId} -> 
        % erlang:display("XXX"),
        tweet_ByUser(UserId),
        relay(N+1);

    {increaseFollower,UserId,FollowId} -> 
        increase_Follower(UserId,FollowId),
        increase_Following(FollowId,UserId),
        relay(N+1);

    {disconnectTheUser,UserId} -> 
        disconnectTheUser(UserId),
        relay(N+1);
    {loginTheUser,UserId,Pid} -> 
        ets:insert(registry,{UserId,Pid}),
        relay(N+1);
    {replyHashtag,Data} ->
        erlang:display(Data),
        relay(N+1)
    end.

spot_user(UserId) ->
    Check = ets:lookup(registry,UserId),
    if 
       Check == [] ->
            [];
       true ->
            [Tuple] = ets:lookup(registry, UserId),
            element(2,Tuple)
    end.
    % [Tuple] = ets:lookup(registry,UserId),
    % element(2,Tuple).

registering(UserId,Pid)->
    
        ets:insert(registry, {UserId,Pid}),
        ets:insert(tweets, {UserId, []}),
        ets:insert(followingto, {UserId, []}),
        Check = ets:lookup(subscribers, UserId),
        if  
            Check == [] ->
                 ets:insert(subscribers, {UserId, []});
            true -> pass
        end.

disconnectTheUser(UserId) ->
    
      ets:insert(registry, {UserId, undefined}).

filter_tweets(UserId) ->
    Check = ets:lookup(tweets,UserId),
    if 
       Check == [] ->
            [];
        true ->
            [Tuple] = ets:lookup(tweets, UserId),
            element(2,Tuple)
    end.

tweet_ByUser(UserId) ->
    [Tuple] = ets:lookup(tweets,UserId),
    Data = element(2,Tuple),
    Receiver = spot_user(UserId),
    erlang:display(Data),
    % Data.
    Receiver ! {repmyTweets,Data}. 

find_follow(UserId) ->
    [Tuple] = ets:lookup(followingto, UserId),
    element(2,Tuple).

increase_Follower(UserId,FollowId) ->
        [Tuple] = ets:lookup(followingto, UserId),
        Following = element(2,Tuple),
        Data = [FollowId | Following],
        ets:insert(followingto, {UserId, Data}).

find_subscribers(UserId) ->
    [Tuple] = ets:lookup(subscribers, UserId),
    element(2,Tuple).

increase_Following(FollowId,UserId) ->
    Check = ets:lookup(subscribers, FollowId),
    if 
         Check == [] ->
            ets:insert(subscribers, {FollowId, []});
        true -> pass
    end,
    [Tuple] = ets:lookup(subscribers,FollowId),
    Followers = element(2,Tuple),
    Data = [UserId | Followers],
    ets:insert(subscribers, {FollowId, Data}).

tweet(Tweet,UserId)->
    [Tuple] = ets:lookup(tweets, UserId),
    List = element(2,Tuple),
    List_updated = [Tweet | List],
    % io:format("~s", ["\n"]),
    % io:format([Tweet]),
    % io:format("~s", ["\n"]),
    ets:insert(tweets,{UserId,List_updated}),
    Check= re:run(Tweet,"#[a-zA-Z0-9_]+",[global]),
    if 
        Check /= nomatch ->
                {match , All_hashtags} = Check,
                find_mentions_hash(All_hashtags,length(All_hashtags),Tweet);
        true -> ok
    end,
    
    Check_@ = re:run(Tweet,"@[a-zA-Z0-9_]+",[global]),
    if 
        Check_@ /= nomatch ->
                {match , All_mentions} = Check_@,
                find_mentions_hash(All_mentions,length(All_mentions),Tweet,mentions),
                [{_,Subscribers}] = ets:lookup(subscribers, UserId),
                % [Tuple] = ets:lookup(subscribers, UserId),
                % Subscribers = element(2,Tuple),
                package_for_subs(Subscribers,Tweet);
        true -> ok
    end.


package_for_subs([],Tweet) -> pass;

package_for_subs([Subscriber | A],Tweet) ->
    Check = spot_user(Subscriber),
    if 
        Check /= [] ->
                erlang:display(Tweet),
                erlang:display("XXXXXXXX"),
                spot_user(Subscriber) ! {live,Tweet};
        true ->
            pass
    end,
    package_for_subs(A,Tweet).



find_mentions_hash([],0,Str)-> pass;

find_mentions_hash([A | B],L,Str)->
    [C | D] = A,
    {Initiate,Length} = C,
    Sublist = lists:sublist(Str, Initiate+1, Length),
    % erlang:display(Sublist),
    update_tags(Sublist,Str),
    find_mentions_hash(B,L-1,Str).

find_mentions_hash([],0,Str,mentions)-> pass;

find_mentions_hash([A | B],L,Str,mentions)->
    [C | D] = A,
    {Initiate,Length} = C,
    Sublist = lists:sublist(Str, Initiate+1, Length),
    % erlang:display(Sublist),
    Name = lists:sublist(Str, Initiate+2, Length-1),
    Check = spot_user(Name),
    if 
        Check /= [] ->
                spot_user(Name) ! {live,Str};
        true -> user_not_found
    end,
    update_tags(Sublist,Str),
    find_mentions_hash(B,L-1,Str).

update_tags(Tag,Tweet) ->
    Check = ets:lookup(hashtags_mentions, Tag),
    if 
        Check /= [] ->
                [Tuple] = ets:lookup(hashtags_mentions, Tag),
                All_tweet_data = element(2,Tuple),
                Data = [Tweet | All_tweet_data],
                ets:insert(hashtags_mentions,{Tag,Data});
                
        true ->
            ets:insert(hashtags_mentions,{Tag,[Tweet]})
    end.

subscriptions(UserId) ->
        Following = find_follow(UserId),
        Data = generate_data(Following,[]),
        spot_user(UserId) ! {repusersSubscribedTo,Data}.
        
generate_data([],Tweetstr) -> Tweetstr;

generate_data([A | B],Tweetstr) ->
    New = filter_tweets(A) ++ Tweetstr,
    generate_data(B,New).


tweetContaininghashtag(HashTag,UserId) ->
    Check = ets:lookup(hashtags_mentions, HashTag),
    if 
        Check /= [] ->
                [Tuple] = Check;

        true ->
                [Tuple] = [{"#",[]}]
    end,
    Data = element(2,Tuple),
    Receiver = spot_user(UserId),
    % Receiver.
    Receiver ! {replyHashtags,Data}.

tweetContainingMention(UserId) ->
    Q = "@"++integer_to_list(UserId),
    % erlang:display(Q),
    Check = ets:lookup(hashtags_mentions, Q),
    if 
         Check /= [] ->
                [Tuple] = Check;

        true ->
                [Tuple] = [{"#",[]}]
    end,
    Data = element(2,Tuple),
    spot_user(UserId) ! {repmentionTweets,Data}.

begin_server() ->
    %ets:new(ingredients, [set,public, named_table]),
    ets:new(registry, [set, public, named_table]),
    ets:new(tweets, [set, public, named_table]),
    ets:new(hashtags_mentions, [set, public, named_table]),
    ets:new(followingto, [set, public, named_table]),
    ets:new(subscribers, [set, public, named_table]),
    Pid = new(),
    global:register_name(server, Pid).

