# roBa トラブル調査スクリプト（問題が起きているノート PC で実行）
# ※ roBa を USB 直挿しして「重い」状態にしてから実行してください
# 結果はデスクトップの roba-diag.txt に保存されます

$out = Join-Path ([Environment]::GetFolderPath('Desktop')) 'roba-diag.txt'
Start-Transcript -Path $out -Force | Out-Null

"########## roBa 調査 $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') ##########"
"PC: $env:COMPUTERNAME / $((Get-CimInstance Win32_ComputerSystem).Model)"
"OS: $((Get-CimInstance Win32_OperatingSystem).Caption) $((Get-CimInstance Win32_OperatingSystem).Version)"

"`n########## 1. Bluetooth アダプタ（複数あると競合する） ##########"
Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue |
  Where-Object { $_.InstanceId -match '^USB\\|^PCI\\' } |
  Select-Object Status, FriendlyName, InstanceId | Format-Table -AutoSize -Wrap

"`n--- 上記アダプタの問題コード ---"
Get-PnpDevice -Class Bluetooth -ErrorAction SilentlyContinue |
  Where-Object { $_.InstanceId -match '^USB\\|^PCI\\' } | ForEach-Object {
    $pc = (Get-PnpDeviceProperty -InstanceId $_.InstanceId -KeyName DEVPKEY_Device_ProblemCode -ErrorAction SilentlyContinue).Data
    "{0,-50} Status={1} ProblemCode={2}" -f $_.FriendlyName, $_.Status, $pc
  }

"`n########## 2. roBa のデバイスエントリ（USB / BLE 両方・切断済み含む） ##########"
Get-PnpDevice -ErrorAction SilentlyContinue |
  Where-Object { $_.InstanceId -match 'VID_1D50|VID&011D50' -or $_.FriendlyName -match 'roBa' } |
  Select-Object Status, Class, FriendlyName, InstanceId | Sort-Object Class | Format-Table -AutoSize -Wrap

"`n--- roBa USB の接続先（直挿し か ハブ経由 か） ---"
$roba = Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.InstanceId -match '^USB\\VID_1D50' }
if ($roba) {
  foreach ($r in $roba) {
    $par = (Get-PnpDeviceProperty -InstanceId $r.InstanceId -KeyName DEVPKEY_Device_Parent -ErrorAction SilentlyContinue).Data
    $loc = (Get-PnpDeviceProperty -InstanceId $r.InstanceId -KeyName DEVPKEY_Device_LocationInfo -ErrorAction SilentlyContinue).Data
    "Name  : $($r.FriendlyName)"
    "Id    : $($r.InstanceId)"
    "Parent: $par"
    "Loc   : $loc`n"
  }
} else { "!!! roBa が USB で見えていません（USB 接続して再実行してください）" }

"`n########## 3. 異常デバイス ##########"
Get-PnpDevice -PresentOnly -ErrorAction SilentlyContinue | Where-Object { $_.Status -ne 'OK' } |
  Select-Object Status, Class, FriendlyName, InstanceId | Format-Table -AutoSize -Wrap

"`n########## 4. イベントログ（BT / USB / PnP・過去14日） ##########"
try {
  Get-WinEvent -FilterHashtable @{LogName='System'; StartTime=(Get-Date).AddDays(-14)} -ErrorAction Stop |
    Where-Object { $_.ProviderName -match 'BTHUSB|Bluetooth|USB|Kernel-PnP|Wdf' -and $_.LevelDisplayName -match 'エラー|警告|Error|Warning' } |
    Select-Object -First 40 TimeCreated, ProviderName, Id, LevelDisplayName,
      @{n='Msg';e={($_.Message -split "`n")[0]}} | Format-Table -AutoSize -Wrap
} catch { "イベント取得失敗: $_" }

"`n########## 5. 負荷測定（8秒） ##########"
$sec = 8
$cores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
$p1 = @{}; Get-Process | ForEach-Object { try { $p1[$_.Id] = @{N=$_.ProcessName; C=$_.CPU} } catch {} }
$cnt = '\Processor(_Total)\% DPC Time','\Processor(_Total)\% Interrupt Time','\Processor(_Total)\% Processor Time','\Processor(_Total)\Interrupts/sec'
$samples = Get-Counter -Counter $cnt -SampleInterval 1 -MaxSamples $sec -ErrorAction SilentlyContinue
$p2 = @{}; Get-Process | ForEach-Object { try { $p2[$_.Id] = @{N=$_.ProcessName; C=$_.CPU} } catch {} }

"--- プロセス別 CPU 上位15（論理コア $cores 個・全体比 %）---"
$rows = foreach ($id in $p2.Keys) {
  if ($p1.ContainsKey($id)) {
    $d = $p2[$id].C - $p1[$id].C
    if ($d -gt 0.05) { [PSCustomObject]@{ Process=$p2[$id].N; PID=$id; 'CPU%'=[math]::Round($d/$sec/$cores*100,2) } }
  }
}
$rows | Sort-Object 'CPU%' -Descending | Select-Object -First 15 | Format-Table -AutoSize

"--- カーネル: DPC / 割り込み（デスクトップ基準値: DPC 0.09 / INT 0.15 / CPU 3.0 / Int_s 39500）---"
foreach ($c in $cnt) {
  $leaf = $c.Split('\')[-1]
  $vals = $samples | ForEach-Object { ($_.CounterSamples | Where-Object { $_.Path -like "*$leaf*" }).CookedValue }
  if ($vals) {
    "{0,-24} 平均 {1,10}  最大 {2,10}" -f $leaf,
      [math]::Round(($vals | Measure-Object -Average).Average,2),
      [math]::Round(($vals | Measure-Object -Maximum).Maximum,2)
  }
}

"`n########## 6. 常駐している周辺機器ソフト ##########"
Get-Process | Where-Object { $_.ProcessName -match 'iCUE|Corsair|lghub|Logi|NZXT|CAM|Razer|Armoury|Synapse|OpenRGB|SignalRgb|Wootility|Vial|Via' } |
  Select-Object ProcessName, Id, @{n='CPU累計s';e={[math]::Round($_.CPU,1)}}, @{n='MEM_MB';e={[math]::Round($_.WorkingSet64/1MB,0)}} |
  Sort-Object CPU累計s -Descending | Format-Table -AutoSize

"`n########## 7. ゴーストデバイス数 ##########"
$all = Get-PnpDevice -ErrorAction SilentlyContinue
"全デバイス: $($all.Count) / 未接続(Unknown): $(($all | Where-Object { $_.Status -eq 'Unknown' }).Count)"

"`n########## 完了 ##########"
Stop-Transcript | Out-Null
Write-Host "`n結果を書き出しました: $out" -ForegroundColor Green
