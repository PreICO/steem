#pragma once
#include <steemit/plugins/block_api/block_api_objects.hpp>

#include <steemit/protocol/types.hpp>
#include <steemit/protocol/transaction.hpp>
#include <steemit/protocol/block_header.hpp>

#include <steemit/plugins/json_rpc/utility.hpp>

namespace steemit { namespace plugins { namespace block_api {

/* get_block */

struct get_block_args
{
   uint32_t block_num;
};

struct get_block_return
{
   optional< api_signed_block_object > block;
};

} } } // steemit::block_api

FC_REFLECT( steemit::plugins::block_api::get_block_args,
   (block_num) )

FC_REFLECT( steemit::plugins::block_api::get_block_return,
   (block) )
