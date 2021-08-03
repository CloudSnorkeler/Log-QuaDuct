


###################################################################################################
#
#            Cloudwatch Sub Filters & Destinations
#
####################################################################################################
        module "cloudwatch_sub_filters_data-coll_us-east-1" {
        providers = {
          aws = "aws.collection-east-1"
        }
        source = "../../../modules/cloudwatch/"
        service_name                = local.service_name
        tags                        = local.tags
        cloudwatch_agg_arn          = module.kinesis_data_firehose_data-coll_logs-us-east-1.log_group_destination
        filter_pattern              = ""
      }