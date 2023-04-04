-module(maine).
-export([jum/3,convergence_checker/7,spinUsers/3,spot_user/1,simulation_disconnection/2,spin_up/1,tackling_disconnection/4]).

% -export([initiate/3,check_convergence/7,spawnUsers/3,find_user/1,disconnection_simulator/2,spawn_up/1,disconnection_handler/4]).
% -import(server,[]).
-import(cliente,[]).

jum(ClientCount,MaximumSubcribers,DisconnectedCl) ->
    CountToDisconnect = DisconnectedCl * (0.01) * ClientCount,
    ets:new(registrymain, [set, public, named_table]),
    Pid = spawn(fun() ->  convergence_checker(ClientCount,ClientCount,0,0,0,0,0) end),
    global:register_name(mained,Pid),
    Start_time = erlang:system_time(millisecond),
    spinUsers(1,ClientCount,MaximumSubcribers),
    simulation_disconnection(ClientCount,CountToDisconnect).

convergence_checker(0,TotalClients,Tweets_TD,Queries_TD,Hashtag_TD,Mention_TD,MyTweets_TD) ->
        io:format("Mean time taken for tweets~f~n.",[Tweets_TD/TotalClients]),
        io:format("Mean time taken for query of subscribed tweets  ~f~n.", [Queries_TD/TotalClients]),
        io:format("Mean time taken for query of hashtags tweets ~f~n.", [Hashtag_TD/TotalClients]),
        io:format("Mean time taken for query of mention tweets ~f~n.", [Mention_TD/TotalClients]),
        io:format("Mean time taken for query of self tweets ~f~n.", [MyTweets_TD/TotalClients]);

convergence_checker(ClientCount,TotalClients,Tweets_TD,Queries_TD,Hashtag_TD,Mention_TD,MyTweets_TD) ->
    receive 
        {performanceMetrics,A,B,C,D,E} -> convergence_checker(ClientCount-1,TotalClients,Tweets_TD+A,Queries_TD+B,Hashtag_TD+C,Mention_TD+D,MyTweets_TD+E)
    end.

spinUsers(Count,NoOfClients,TotalSubscribers) ->
    UserName = Count,
    NoOfTweets = round(math:floor(TotalSubscribers/Count)),
    NoToSubscribe = round(math:floor(TotalSubscribers/(NoOfClients-Count+1))) - 1,
    % Pid = cliente:initiate([UserName,NoOfTweets,NoToSubscribe,false]),
    Pid = spawn(fun() -> cliente:initiate([UserName,NoOfTweets,NoToSubscribe,false]) end),
    ets:insert(registrymain, {UserName, Pid}),
    if 
        Count /= NoOfClients ->
                spinUsers(Count+1,NoOfClients,TotalSubscribers);
        true -> pass
    end.

spot_user(UserId) ->
    Check = ets:lookup(registrymain,UserId),
    [Tuple] = ets:lookup(registrymain, UserId),
    X = element(2,Tuple),
    if 
       Check == [] ->
            [];
            
       X == undefined ->
            [];
       true ->
            X
            
            
    end.

simulation_disconnection(ClientCount,CountToDisconnect) ->
    timer:sleep(1000),
    Li_disconnect = tackling_disconnection(ClientCount,CountToDisconnect,0,[]),
    timer:sleep(1000),
    spin_up(Li_disconnect),
    simulation_disconnection(ClientCount,CountToDisconnect).

spin_up([]) ->
    pass;

spin_up([A | B]) ->
    Pid = spawn(fun() -> cliente:initiate([A,-1,-1,true]) end),
    ets:insert(registrymain, {A, Pid}),
    spin_up(B).

tackling_disconnection(ClientCount,CountToDisconnect,UsersDisconnected,Li_disconnect) ->
        if 
            UsersDisconnected < CountToDisconnect ->
                DisconnectClient = rand:uniform(ClientCount),
                DisconnectClientId = spot_user(DisconnectClient),
                erlang:display(DisconnectClientId),
                if DisconnectClientId /= [] ->
                    UserId = DisconnectClient,
                    DisconnectList2 = [UserId | Li_disconnect],
                    global:whereis_name(server) ! {disconnectTheUser,UserId},
                    ets:insert(registrymain, {UserId, undefined}),
                    exit(DisconnectClientId, "Disconnected"++DisconnectClientId),
                    io:format("Disconnected the User: ~p.", [UserId]),
                    % IO.puts "Simulator :- User #{userId} has been disconnected"
                    tackling_disconnection(ClientCount,CountToDisconnect,UsersDisconnected+1,DisconnectList2);

                true ->
                tackling_disconnection(ClientCount,CountToDisconnect,UsersDisconnected,Li_disconnect)
            end;
        true ->
            Li_disconnect
        
    end.


