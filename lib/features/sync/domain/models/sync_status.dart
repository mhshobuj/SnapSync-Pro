enum SyncStatus {
  inQueue,
  waitingConnection,
  uploading,
  retrying,
  synced,
  failed,
  paused,
}

extension SyncStatusX on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.inQueue:
        return 'IN QUEUE';
      case SyncStatus.waitingConnection:
        return 'WAITING FOR CONNECTION';
      case SyncStatus.uploading:
        return 'UPLOADING...';
      case SyncStatus.retrying:
        return 'RETRYING...';
      case SyncStatus.synced:
        return 'SYNCED';
      case SyncStatus.failed:
        return 'FAILED / NETWORK ERROR';
      case SyncStatus.paused:
        return 'PAUSED';
    }
  }
}
