-module(lasp_synchronisation_transaction).
-export([new/0, get_buffer/1, add_buffer/3, remove_buffer/2]).
 
% Inspired form: http://erlang.org/pipermail/erlang-questions/2009-June/044893.html 

% This process keep in memory the buffer and the current seq number of the transactions.
% The buffer is build with a map.
% The key follows the form: {node, seqNum}
% The value associated of the wey is: {List, Actor}
% We automatically increment the seqNum for each new entry of the buffer.

new() -> spawn(fun () -> loop({maps:new(), 0}) end).

loop({Buffer, SeqNum}) ->
	receive {Msg,Sender} ->
		Sender ! {self(), {Buffer, SeqNum}},
			loop(case Msg of get_buffer -> {Buffer, SeqNum} ;
					 {add_buffer, K, V} -> {maps:put({K, SeqNum}, V, Buffer), SeqNum+1};
				 	 {remove_buffer, K} -> {maps:remove(K, Buffer), SeqNum}

				 end)
		end.

	get_buffer(Counter) -> ipc(Counter, get_buffer).
	add_buffer(Counter, K, V) -> ipc(Counter, {add_buffer, K, V}).
	remove_buffer(Counter, K) -> ipc(Counter, {remove_buffer, K}).
	ipc(Pid, Msg) when is_pid(Pid) -> 
		Pid ! {Msg, self()},
		receive {Pid, Result} -> {ok, Result} end.