%%%===================================================================
%%% Copyright (c) 2013-2017 EMQ Enterprise, Inc. (http://emqtt.io)
%%%
%%% Licensed under the Apache License, Version 2.0 (the "License");
%%% you may not use this file except in compliance with the License.
%%% You may obtain a copy of the License at
%%%
%%%     http://www.apache.org/licenses/LICENSE-2.0
%%%
%%% Unless required by applicable law or agreed to in writing, software
%%% distributed under the License is distributed on an "AS IS" BASIS,
%%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%% See the License for the specific language governing permissions and
%%% limitations under the License.
%%%===================================================================

-module(ekka_node_ttl).

-behaviour(gen_statem).

%% API
-export([start_link/2]).

%% gen_statem callbacks
-export([init/1, callback_mode/0, handle_event/4, terminate/3, code_change/4]).

-record(state, {ttl, mfa}).

start_link(Ttl, MFA) ->
    gen_statem:start_link({local, ?MODULE}, ?MODULE, [Ttl, MFA], []).

%%%===================================================================
%%% gen_statem callbacks
%%%===================================================================

init([Ttl, MFA]) ->
    {ok, alive, #state{ttl = Ttl, mfa = MFA}, Ttl div 2}.

callback_mode() -> handle_event_function.

handle_event(timeout, _Timeout, alive, State = #state{ttl = Ttl, mfa = {M, F, A}}) ->
    try erlang:apply(M, F, A)
    catch _:Error ->
        lager:error("TTL error: ~p, ~p", [Error, erlang:get_stacktrace()])
    end,
    {next_state, alive, State, Ttl div 2}.

terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.

