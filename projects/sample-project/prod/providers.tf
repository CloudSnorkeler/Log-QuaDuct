
                          

################################################################
#
#            				AWS TF Providers
#
################################################################
      

  provider "aws" {
      region = "us-east-1"
      alias = "collection-east-1"
     assume_role {
        role_arn = "arn:aws:iam::<account-number>:role/<role-name>"
      }
  }


  provider "aws" {
      region = "us-east-1"
      alias = "receiver-east-1"
      assume_role {
        role_arn = "arn:aws:iam::<account-number>:role/<role-name>"
      }
    }
