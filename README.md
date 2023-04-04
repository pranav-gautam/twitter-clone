# twitter-clone
The goal of this project was to implement a clone of Twitter and a client that can test or simulate this server or Twitter clone in Erlang.
In this project we have built a server/engine that in the future will be connected with the Cowboy framework so it can provide complete performance of the now existing twitter. 

## Architecture
![unnamed](https://user-images.githubusercontent.com/64377125/229939166-5fa852f6-17e9-4be6-948d-97c5220b0a55.png)

## Client Side
The way we have implemented our client it takes 3 parameters: 
Number of clients.
Maximum number of subscribers.
Number of clients that have disconnected.

This file contains details on a single client participant, which corresponds to a single twitter user. This includes its userId information, which is saved as a number string supplied to it upon programme startup. The main registry ETS table, which maintains track of numerous actors and is helpful for disconnection and reconnection logic, performs the basic logic of keeping process state. In order to utilize WebSockets, the client was rebuilt. The Cowboy library was used for websockets. The fact that the client was designed as a behavior gave us a great deal of freedom. An error is given if the socket has not joined the topic. The message reference, often known as the ref, is returned upon success.

### Zipf Distribution
It provides the client with the maximum number of subscribers. Then the client with the second most subscribers and then client with third most subscribers and so on. We calculated this using the formula,

No. of subscribers = round(Float.floor(total no. of subscribers/(number of clients-count+1))) - 1

The account that had a lot of subscribers the number of tweets on their account increased and some of these tweets were re-tweets. Number of tweets are calculated using the formula,

No. of tweets = round(Float.floor(total no. of subscribers/count)).

## Server Side
In order to integrate the WebSocket interface, we also completely rewrote our engine in Cowboy. The code for the Twitter engine implementation, which is in charge of handling and dispersing tweets, is located in the "example" folder. To manage subscriptions, tweets, searches, etc., the engine directly interfaces with the database (built using ETS tables). In order to convey the query results, distribute the tweets to subscribers, and other functions, it also directly interacts with clients using Cowboy channels or websockets. The client registry ETS table in the server, which keeps track of numerous actors, maintains process states.

We were able to quickly add soft-real time functionality to our Twitter application thanks to channels. Web sockets are the basis of channels. The server transmits messages on many subjects in its capacity as a sender. Customers take on the role of receivers and subscribe to subjects in order to get such communications. On the same subject, senders and recipients are free to swap roles at any moment.

Our Cowboy server multiplexes channel sockets across a single connection that it holds. The socket handler modules included in lib/example web/channels/user socket.ex enable us to specify default socket assignments for usage across all channels and authenticate and identify a socket connection. WebSockets are used as the standard transport method.

### JSON based API
The first requirement of building a JSON-based API was also met since Cowboy Framework handles the data transport internally using JSON. We examined cowboy.js, which is automatically included when served from Cowboy, to validate this.

# Results
I) When Maximum Subscribers = Number of Clients
![unnamed (1)](https://user-images.githubusercontent.com/64377125/229939548-68a72859-56d5-4bd7-9f46-a6d200443b8a.png)

II) When Maximum Subscribers != Number of Clients
![unnamed (2)](https://user-images.githubusercontent.com/64377125/229939597-4bb8ccd0-62c5-4d64-8ce1-dfc81878ee88.png)

In Erlang, we were able to construct a Twitter clone and a client that can test or mimic the server. ETS Tables served as the database we utilized to store the values of the tweets. And the Cowboy framework was utilized to develop Web Sockets.

We developed a server that offers many features including user account creation and registration. When a user tweets, they must include the special symbols "#" and "@" for the server to recognise the hashtag and the individual they are mentioning. When a user is online, the server displays tweets tailored to their interests and allows them to subscribe to another person or a hashtag.

Additionally, we developed the client for this server, and a maximum of 102312 clients were launched. The client was created using the main function, and it verifies whether or not the server's various features are operational. The formulae presented above in this report were used to compute the number of subscribers and tweets in a client that allowed us to do the zipf distribution. These processes—the client and the server—were built separately. Our client largely concentrates on receiving and sending these tweets, whereas our server's primary task is to disseminate tweets.

Using a stronger CPU will help this project work much better, and we want to link it to WebSockets in the future to make it function precisely like Elon Musk's current Twitter.

(Demonstration:- https://www.youtube.com/watch?v=gTwOcGFF3T0)
