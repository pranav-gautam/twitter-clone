-module(cliente).
-export([initiate/1,login_checker/1,trigger_tweet/2, client_checker/3, produce_sublist/3, handler_zipf/2, handling_retweets/1, tackling_my_tweets/1, tackling_subscribedto/1,
    tackling_hashtag/2,tackling_mention/1,generate_string/1,handleit_live/1,arranging_data/1]).

initiate([UserId,Count_o_Tweet,No_o_Subscribe,Check_presence_user]) ->
        % erlang:display([UserId,Count_o_Tweet,No_o_Subscribe,Check_presence_user]),
        if 
        Check_presence_user ->
            % io:format("User got reconnected : ~p.", UserId),
            io:fwrite("Reconnected the User: ~w.",[UserId]),
            io:format("~s", ["\n"]),
            login_checker(UserId);

        true ->
                pass
        end,
        % erlang:display(global:whereis_name(server)),
        global:whereis_name(server) ! {userRegistration,UserId,self()},
        receive 
            {registered} -> 
                io:format("Registered the User: ~w.", [UserId]),
                io:format("~s", ["\n"])
        end,
        client_checker(UserId,Count_o_Tweet,No_o_Subscribe).

login_checker(UserId) ->
        global:whereis_name(server) ! {loginTheUser,UserId,self()},
        trigger_tweet(5,UserId),
        handleit_live(UserId).


trigger_tweet(1,UserId) ->
   
    Q = integer_to_list(UserId),
    global:whereis_name(server) ! {tweet,"user "++Q++" tweeting something cool that is "++generate_string(8)++".",UserId};

trigger_tweet(N,UserId) ->
    Sende = generate_string(8),
    Q = integer_to_list(UserId),
    global:whereis_name(server) ! {tweet,"user "++Q++" tweeting something cool that is "++Sende++".",UserId},
    trigger_tweet(N-1,UserId).

client_checker(UserId,Count_o_Tweet,No_o_Subscribe) ->
        if 
        No_o_Subscribe > 0 ->
            SubList = produce_sublist(1,No_o_Subscribe,[]),
            % erlang:display(SubList),
            handler_zipf(UserId,SubList);

        true ->
                pass
        end,
        Start_time_tweet = erlang:system_time(millisecond),
        UserToMention = integer_to_list(UserId),
        global:whereis_name(server) ! {tweet,"user "++UserToMention++" is mentioning the user @"++UserToMention,UserId},
        global:whereis_name(server) ! {tweet,"user "++UserToMention++" is tweeting that #UF are awesome",UserId},

        trigger_tweet(Count_o_Tweet,UserId),
        handling_retweets(UserId),
        Tweets_TD = erlang:system_time(millisecond) - Start_time_tweet,

        Start_time_query = erlang:system_time(millisecond),
        tackling_subscribedto(UserId),
        Queries_TD = erlang:system_time(millisecond) - Start_time_query,

        Start_time_hash_search = erlang:system_time(millisecond),
        tackling_hashtag("#UF",UserId),
        Hashtag_TD = erlang:system_time(millisecond) - Start_time_hash_search,

        Start_time_mention = erlang:system_time(millisecond),
        tackling_mention(UserId),
        Mention_TD = erlang:system_time(millisecond) - Start_time_mention,

        Start_time_my_tweets = erlang:system_time(millisecond),
        tackling_my_tweets(UserId),
        MyTweets_TD = erlang:system_time(millisecond) - Start_time_my_tweets,

        Tweets_time_diff_modi = Tweets_TD/(Count_o_Tweet+3),
        global:whereis_name(mained) ! {performanceMetrics,Tweets_TD,Queries_TD,Hashtag_TD,Mention_TD,MyTweets_TD},
        % send(:global.whereis_name(:mained),)

        handleit_live(UserId).

produce_sublist(Count,Subs,Li) ->
    if
        Count == Subs ->  
            [Count | Li];
        true -> 
            produce_sublist(Count+1,Subs,[Count | Li]) 
    end.

handler_zipf(UserId,[]) -> pass;
    

handler_zipf(UserId,[A | B]) ->
    global:whereis_name(server) ! {increaseFollower,UserId,A},
    handler_zipf(UserId,B).

handling_retweets(UserId) ->
    global:whereis_name(server) ! {subscriptions,UserId},
    receive 
        {repusersSubscribedTo,Data} ->
            Pass = Data
    end,
    if Pass /= [] ->
        [Retweet | B] = Pass,
        global:whereis_name(server) ! {tweet,Retweet++" -RT",UserId};
    true ->
        nothing_to_retweet
    end.

handleit_live(UserId) ->
    receive 
        {live,St} ->
            io:format("Live happening of a User : ~w.", [UserId]),
            io:format("~s", ["\n"]),
            io:format([St]),
            io:format("~s", ["\n"])
    end,
    handleit_live(UserId).

tackling_my_tweets(UserId) ->
    global:whereis_name(server) ! {tweetByUser,UserId},
    receive 
        {repmyTweets,Data} ->
            io:format("All Tweets tweeted by User : ~w.", [UserId]),
            io:format("~s", ["\n"]),
            arranging_data(Data),
            io:format("~s", ["\n"])
    end.

tackling_subscribedto(UserId) ->
    global:whereis_name(server) ! {subscriptions,UserId},
    receive
        {repusersSubscribedTo,Data} ->
            io:format("All Tweets tweeted by subscribers of User : ~w.", [UserId]),
            io:format("~s", ["\n"]),
            arranging_data(Data),
            io:format("~s", ["\n"])
    end.

arranging_data([]) -> end_reached;
arranging_data([A | B]) ->
    io:format("~s", ["\n"]),
    io:format(A),
    % io:format("~s", ["\n"]),
    arranging_data(B).

tackling_hashtag(Tag,UserId) ->
    global:whereis_name(server) ! {tweetContaininghashtag,Tag,UserId},
    receive
        {replyHashtags,Data} ->
            io:format("All "++Tag++" Tweets queried by User : ~w.", [UserId]),
            io:format("~s", ["\n"]),
            % io:format(Data),
            arranging_data(Data),
            io:format("~s", ["\n"])
    end.

tackling_mention(UserId) ->
    Q = "@"++integer_to_list(UserId),
    global:whereis_name(server) ! {tweetContainingMention,UserId},
    receive
        {repmentionTweets,Data} ->
            io:format("All Tweets about the user "++Q++" requested by : ~w.", [UserId]),
            io:format("~s", ["\n"]),
            arranging_data(Data),
            io:format("~s", ["\n"])
    end.


generate_string(Total_length) ->
    Chars_allowed = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    lists:foldl(fun(_, Accumulator) ->
                       [lists:nth(rand:uniform(length(Chars_allowed)),
                                   Chars_allowed)]
                            ++ Accumulator
                end, [], lists:seq(1, Total_length)).






