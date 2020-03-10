%% The contents of this file are subject to the Mozilla Public License
%% Version 1.1 (the "License"); you may not use this file except in
%% compliance with the License. You may obtain a copy of the License
%% at https://www.mozilla.org/MPL/
%%
%% Software distributed under the License is distributed on an "AS IS"
%% basis, WITHOUT WARRANTY OF ANY KIND, either express or implied. See
%% the License for the specific language governing rights and
%% limitations under the License.
%%
%% The Original Code is RabbitMQ Consistent Hash Exchange.
%%
%% The Initial Developer of the Original Code is GoPivotal, Inc.
%% Copyright (c) 2007-2020 VMware, Inc. or its affiliates.  All rights reserved.
%%

-module(rabbit_exchange_type_management_SUITE).

-compile(export_all).

-include_lib("common_test/include/ct.hrl").
-include_lib("eunit/include/eunit.hrl").
-include_lib("amqp_client/include/amqp_client.hrl").

-import(rabbit_ct_client_helpers, [open_connection_and_channel/1,
                                   close_connection_and_channel/2]).

all() ->
    [
      overview_with_single_column,
      overview_with_all_columns,
      list_users
     ].

init_per_suite(Config) ->
    rabbit_ct_helpers:log_environment(),
    Config1 = rabbit_ct_helpers:set_config(Config, [
        {rmq_nodename_suffix, ?MODULE}
      ]),
    rabbit_ct_helpers:run_setup_steps(Config1,
      rabbit_ct_broker_helpers:setup_steps() ++
      rabbit_ct_client_helpers:setup_steps()).

end_per_suite(Config) ->
    rabbit_ct_helpers:run_teardown_steps(Config,
      rabbit_ct_client_helpers:teardown_steps() ++
      rabbit_ct_broker_helpers:teardown_steps()).

init_per_group(_, Config) ->
    Config.

end_per_group(_, Config) ->
    Config.

init_per_testcase(Testcase, Config) ->
    rabbit_ct_helpers:testcase_started(Config, Testcase).

end_per_testcase(Testcase, Config) ->
    rabbit_ct_helpers:testcase_finished(Config, Testcase).

%%
%% Tests
%%

overview_with_single_column(Config) ->
    basic_overview_test(Config, <<"/overview?columns=rabbitmq_version">>).

overview_with_all_columns(Config) ->
    basic_overview_test(Config, <<"/overview">>).

list_users(Config) ->
    run_test(Config, fun() ->
                      #'basic.publish'{exchange    = <<"mgmt">>,
                                       routing_key = <<"/users/">>}
                     end,
                     fun(ReplyQ, CorrelationId) ->
                       #amqp_msg{props   = #'P_basic'{reply_to       = ReplyQ,
                                                      type           = <<"GET">>,
                                                      correlation_id = CorrelationId},
                                 payload = <<"">>}
                     end,
                     fun(_, #amqp_msg{props   = Props,
                                      payload = Payload}, CorrelationId) ->
                       ?assertMatch(<<"200">>, Props#'P_basic'.type),
                       ?assertMatch(CorrelationId, Props#'P_basic'.correlation_id),

                       Users = rabbit_json:decode(Payload),
                       ?assert(lists:any(fun(#{<<"name">> := Name}) ->
                                           Name =:= <<"guest">>
                                         end, Users))
                     end).

%%
%% Implementation
%%

basic_overview_test(Config, RoutingKey) ->
    run_test(Config, fun() ->
                        #'basic.publish'{exchange    = <<"mgmt">>,
                                         routing_key = RoutingKey}
                     end,
                     fun(ReplyQ, CorrelationId) ->
                       #amqp_msg{props   = #'P_basic'{reply_to       = ReplyQ,
                                                      type           = <<"GET">>,
                                                      correlation_id = CorrelationId},
                                 payload = <<"">>}
                     end,
                     fun(_, #amqp_msg{props   = Props,
                                      payload = _Payload}, CorrelationId) ->
                       ?assertMatch(<<"200">>, Props#'P_basic'.type),
                       ?assertMatch(CorrelationId, Props#'P_basic'.correlation_id)
                     end).

run_test(Config, BasicPublishFun, MessageFun, AssertionFun) ->
    {Conn, Ch} = open_connection_and_channel(Config),
    #'exchange.declare_ok'{} =
        amqp_channel:call(
          Ch, #'exchange.declare'{exchange = <<"mgmt">>,
                                  type     = <<"x-management">>}),
    #'queue.declare_ok'{queue = Q} =
        amqp_channel:call(Ch, #'queue.declare'{exclusive = true}),

    Id = rabbit_ct_broker_helpers:rpc(Config, 0, rabbit_guid, gen, []),

    BasicPublish = BasicPublishFun(),
    amqp_channel:cast(Ch, BasicPublish, MessageFun(Q, Id)),
    amqp_channel:subscribe(Ch, #'basic.consume'{queue = Q, no_ack = true},
                           self()),

    receive
        #'basic.consume_ok'{} -> ok
    end,

    receive
        {BasicDeliver, Message} ->
            AssertionFun(BasicDeliver, Message, Id)
    end,

    close_connection_and_channel(Conn, Ch).
