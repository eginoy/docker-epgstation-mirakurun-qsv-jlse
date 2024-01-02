#!/bin/bash

#epgstationの録画予約情報などをバックアップ
docker exec -i epgstation npm run backup data/backup/setting.bk
