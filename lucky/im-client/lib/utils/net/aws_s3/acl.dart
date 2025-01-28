enum ACL {
  /// Owner gets FULL_CONTROL. No one else has access rights (default).
  private,

  /// Owner gets FULL_CONTROL. The AllUsers group (see Who is a grantee?) gets READ access.
  public_read,

  /// Owner gets FULL_CONTROL. The AllUsers group gets READ and WRITE access. Granting this on a bucket is generally not recommended.
  public_read_write,

  /// Owner gets FULL_CONTROL. Amazon EC2 gets READ access to GET an Amazon Machine Image (AMI) bundle from Amazon S3.
  aws_exec_read,

  /// Owner gets FULL_CONTROL. The AuthenticatedUsers group gets READ access.
  authenticated_read,

  /// Object owner gets FULL_CONTROL. Bucket owner gets READ access. If you specify this canned ACL when creating a bucket, Amazon S3 ignores it.
  bucket_owner_read,

  /// Both the object owner and the bucket owner get FULL_CONTROL over the object. If you specify this  dcanned ACL when creating a bucket, Amazon S3 ignores it.
  bucket_owner_full_control,

  /// The LogDelivery group gets WRITE and READ_ACP permissions on the bucket. For more information about logs
  log_delivery_write,
}

String aclToString(ACL acl) {
  switch (acl) {
    case ACL.private:
      return 'private';
    case ACL.public_read:
      return 'public-read';
    case ACL.public_read_write:
      return 'public-read-write';
    case ACL.aws_exec_read:
      return 'aws-exec-read';
    case ACL.authenticated_read:
      return 'authenticated-read';
    case ACL.bucket_owner_read:
      return 'bucket-owner-read';
    case ACL.bucket_owner_full_control:
      return 'bucket-owner-full-control';
    case ACL.log_delivery_write:
      return 'log-delivery-write';
  }
}
