<#
subplacegui.ps1 version 1.2
made by kit ^_^ https://vyz.ee/
subject to the terms of the MPL 2.0, you can get a copy at http://mozilla.org/MPL/2.0/
#>

$version  = "1.2"
$jsonPath = "$env:LOCALAPPDATA\subplace\gui\settings.json"
Add-Type -AssemblyName PresentationFramework

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
	xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
	Title="subplacegui" Height="450" Width="600">
	<TabControl x:Name="MainTabControl">
		<TabItem Header="Main">
			<Grid>
				<Grid.RowDefinitions>
					<RowDefinition Height="Auto"/>
					<RowDefinition Height="*"/>
					<RowDefinition Height="Auto"/>
				</Grid.RowDefinitions>
				<Grid Margin="10">
					<Grid.ColumnDefinitions>
						<ColumnDefinition Width="Auto" />
						<ColumnDefinition Width="Auto" />
						<ColumnDefinition Width="Auto" />
						<ColumnDefinition Width="*" />
					</Grid.ColumnDefinitions>
					<TextBox x:Name="PlaceIdInput" Width="150" Margin="0,0,10,0" Grid.Column="0"/>
					<Button Content="Load PlaceID" Margin="0,0,10,0" x:Name="LoadPlaceIdButton" Grid.Column="1"/>
					<TextBlock Grid.Column="2" Margin="0,2,10,0">JobID:</TextBlock>
					<TextBox x:Name="JobIdInput" HorizontalAlignment="Stretch" Grid.Column="3"/>
				</Grid>
				<DataGrid x:Name="PlacesGrid" Grid.Row="1" AutoGenerateColumns="False" Margin="10" IsReadOnly="True" HeadersVisibility="Column" VirtualizingPanel.ScrollUnit="Pixel">
					<DataGrid.Columns>
						<DataGridTextColumn Header="Name" Binding="{Binding name}" Width="*"/>
						<DataGridTextColumn Header="ID" Binding="{Binding id}" Width="Auto"/>
					</DataGrid.Columns>
				</DataGrid>
				<StackPanel Grid.Row="2" Margin="10,0,10,10" Orientation="Horizontal">
					<TextBlock x:Name="StatusDot" Foreground="Gray" FontFamily="Segoe UI Symbol Regular">&#x26AB;&#x2002;</TextBlock>
					<TextBlock x:Name="StatusText">Joining process hasn't begun yet.</TextBlock>
				</StackPanel>
			</Grid>
		</TabItem>
		<TabItem Header="Settings">
			<Grid Margin="10">
				<Grid.RowDefinitions>
					<RowDefinition Height="Auto"/>
					<RowDefinition Height="*"/>
					<RowDefinition Height="Auto"/>
				</Grid.RowDefinitions>
				<StackPanel Margin="0" Grid.Row="0">
					<StackPanel Orientation="Horizontal" Margin="-5,0,0,0" x:Name="DelayStack" Visibility="Collapsed">
						<Label Content="Delay:" Target="{Binding ElementName=Delay}"/>
						<TextBox x:Name="Delay" Text="750" HorizontalAlignment="Left" Width="150" Height="18"/>
					</StackPanel>
					<StackPanel Orientation="Horizontal" Margin="-5,0,0,8">
						<Label Content="Loop Delay:" Target="{Binding ElementName=LoopDelay}"/>
						<TextBox x:Name="LoopDelay" Text="300" HorizontalAlignment="Left" Width="150" Height="18"/>
					</StackPanel>
					<CheckBox x:Name="SudoMode" Content="Enable sudo mode" Margin="0,0,0,10"/>
					<CheckBox x:Name="SkipPrejoining" Content="Skip pre-joining" Margin="0,0,0,10"/>
					<CheckBox x:Name="ManualMode" Content="Manual Mode" Margin="0,0,0,10"/>
					<CheckBox x:Name="VerboseMode" Content="Verbose Mode" Margin="0,0,0,10"/>
				</StackPanel>
				<TextBlock x:Name="SavedMessage" Text="Settings Saved" Foreground="Green" Margin="0,-10,0,10" Grid.Row="2" Visibility="Hidden"/>
				<Button Content="Save Settings" 
					VerticalAlignment="Bottom" 
					HorizontalAlignment="Stretch" 
					Margin="0,10,0,0" 
					x:Name="SaveSettingsButton"
					Grid.Row="2"/>
			</Grid>
		</TabItem>
		<TabItem Header="Info">
		<Grid Margin="10">
			<Grid.RowDefinitions>
				<RowDefinition Height="Auto"/>
				<RowDefinition Height="*"/>
			</Grid.RowDefinitions>
			<StackPanel Grid.Row="0">
				<TextBlock Margin="0,0,0,5">subplacegui 1.2 by kit</TextBlock>
				<TextBlock Margin="0,0,0,5"><Hyperlink x:Name="GithubLink" NavigateUri="https://github.com/catb0x/subplace">Github</Hyperlink></TextBlock>
				<TextBlock Margin="0,0,0,5" Foreground="Gray">rgc was here ^_^ stan loona :3</TextBlock>
				<TextBlock Margin="0,0,0,5" Foreground="Gray">thanks to <Hyperlink x:Name="ReturnLink" NavigateUri="https://github.com/returnrqt">return</Hyperlink> for helping me with this</TextBlock>
			</StackPanel>
			<Image HorizontalAlignment="Stretch" 
				Source="https://i.pinimg.com/originals/d8/13/03/d81303b0eacb154411c932e92b2b75a3.jpg"
				Stretch="Uniform"
				VerticalAlignment="Bottom"
				Grid.Row="1"/>
		</Grid>
		</TabItem>
	</TabControl>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

$mainTabControl         = $window.FindName("MainTabControl")
$placeIdInput           = $window.FindName("PlaceIdInput")
$jobIdInput             = $window.FindName("JobIdInput")
$loadPlaceIdButton      = $window.FindName("LoadPlaceIdButton")
$placesGrid             = $window.FindName("PlacesGrid")
$delayStack             = $window.FindName("DelayStack")
$delayInput             = $window.FindName("Delay")
$loopDelayInput         = $window.FindName("LoopDelay")
$sudoModeCheckbox       = $window.FindName("SudoMode")
$saveSettingsButton     = $window.FindName("SaveSettingsButton")
$savedMessageText       = $window.FindName("SavedMessage")
$skipPrejoiningCheckbox = $window.FindName("SkipPrejoining")
$manualModeCheckbox     = $window.FindName("ManualMode")
$verboseModeCheckbox    = $window.FindName("VerboseMode")
$statusText             = $window.FindName("StatusText")
$statusDot              = $window.FindName("StatusDot")
$githubLink             = $window.FindName("GithubLink")
$returnLink             = $window.FindName("ReturnLink")

foreach ($element in @($githubLink, $returnLink)) {
	if ($element -ne $null) {
		$element.Add_Click({
			Start-Process $this.NavigateUri.AbsoluteUri
		})
	}
}

$fadeOut = New-Object Windows.Media.Animation.DoubleAnimation
$fadeOut.From = 1.0
$fadeOut.To = 0.0
$fadeOut.Duration = [System.Windows.Duration]::new([System.TimeSpan]::FromSeconds(0.5))

if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Start-Process powershell -ArgumentList "-NoExit", "-noprofile", "-executionpolicy bypass", "-file `"$PSCommandPath`"" -Verb RunAs
	exit
}
if (!(Get-Command "gsudo" -ErrorAction SilentlyContinue)) {
	$sudoModeCheckbox.Visibility = [System.Windows.Visibility]::Collapsed
}

$sudoModeCheckBox.Add_Checked({ $script:sudoMode = $true })
$sudoModeCheckBox.Add_Unchecked({ $script:sudoMode = $false })
$skipPrejoiningCheckbox.Add_Checked({ $script:skipPrejoining = $true })
$skipPrejoiningCheckbox.Add_Unchecked({ $script:skipPrejoining = $false })
$verboseModeCheckbox.Add_Checked({ $script:VerbosePreference = "Continue" })
$verboseModeCheckbox.Add_Unchecked({ $script:VerbosePreference = "SilentlyContinue" })
$manualModeCheckbox.Add_Checked({
	$script:manualMode = $true
	$delayStack.Visibility = [System.Windows.Visibility]::Visible
})
$manualModeCheckbox.Add_Unchecked({
	$script:manualMode = $false
	$delayStack.Visibility = [System.Windows.Visibility]::Collapsed
})

$jobIdInput.add_PreviewTextInput({
	param($sender, $e)
	if (-not [regex]::IsMatch($e.Text, '^[a-z0-9-]*$')) {
		$e.Handled = $true
	}
})

$jobIdInput.Add_TextChanged({
	if ($jobIdInput.Text -ne "") {
		$script:jobIdString = "&gameInstanceId=$($jobIdInput.Text)"
		Write-Host $jobIdString
	} else {
		$script:jobIdString = ""
	}
})

$NumberValidationTextBox = {
	param($sender, $e)
	if (-not [char]::IsDigit($e.Text[0])) {
		$e.Handled = $true
	}
}

$delayInput.Add_PreviewTextInput($NumberValidationTextBox)
$delayInput.Add_TextChanged({
	if ([int]::TryParse($delayInput.Text, [ref]$null)) {
		$script:delay = [int]$delayInput.Text
	}
})

$loopDelayInput.Add_PreviewTextInput($NumberValidationTextBox)
$loopDelayInput.Add_TextChanged({
	if ([int]::TryParse($loopDelayInput.Text, [ref]$null)) {
		$script:loopDelay = [int]$loopDelayInput.Text
	}
})

$loadPlaceIdButton.Add_Click({
	$placeId = $placeIdInput.Text
	if (-not [string]::IsNullOrEmpty($placeId)) {
		try {
			$request       = Invoke-RestMethod -Uri "https://apis.roblox.com/universes/v1/places/$placeId/universe"
			$universeId    = $request.universeId
			$rootRequest   = Invoke-RestMethod -Uri "https://games.roblox.com/v1/games?universeIds=$universeId"
			$script:rootId = $rootRequest.data[0].rootPlaceId
			if ($placeId -eq $script:rootId) {
				$allPlaces = @()
				$cursor	= ""
				while ($true) {
					$places = Invoke-RestMethod -Uri "https://develop.roblox.com/v1/universes/$universeId/places?limit=100&cursor=$cursor"
					$allPlaces += $places.data
					if ($places.nextPageCursor) {
						$cursor = $places.nextPageCursor
					} else {
						break
					}
				}
				$placesGrid.ItemsSource = $allPlaces
			} else {
				$script:subplace = $placeId
				Join
			}
		} catch {
			[System.Windows.MessageBox]::Show("Error: $_", "Error")
		}
	}
})

$saveSettingsButton.Add_Click({
	$savedMessageText.Visibility = "Visible"
	$savedMessageText.BeginAnimation([Windows.UIElement]::OpacityProperty, $null)
	$savedMessageText.Opacity = 1.0
	$script:timer = New-Object System.Windows.Threading.DispatcherTimer
	$timer.Interval = [TimeSpan]::FromSeconds(0.5)
	$timer.Add_Tick({
		$savedMessageText.BeginAnimation([Windows.UIElement]::OpacityProperty, $fadeOut)
		$timer.Stop()
	})
	$timer.Start()
	SaveSettings "delay", "loopDelay", "sudoMode", "version", "skipPrejoining", "manualMode", "VerbosePreference"
})

$placesGrid.Add_MouseDoubleClick({
	if ($placesGrid.SelectedItem) {
		$script:subplace = $placesGrid.SelectedItem.id
		Join
	}
})

function SaveSettings {
	param (
		[Parameter(Position=0)]
		[string[]]$VariableNames
	)
	$varHash = @{}
	foreach ($varName in $VariableNames) {
		if (Get-Variable -Name $varName -ErrorAction SilentlyContinue) {
			$varHash[$varName] = (Get-Variable -Name $varName).Value
		}
	}
	New-Item -Path (Split-Path $jsonPath) -ItemType Directory -Force | Out-Null
	$varHash | ConvertTo-Json | Set-Content $jsonPath
}

function LoadSettings {
	if ((Test-Path $jsonPath) -and !($reset)) {
		$varHash = Get-Content $jsonPath | ConvertFrom-Json
		foreach ($key in $varHash.PSObject.Properties.Name) {
			if ($key -ne "version") { Set-Variable -Name $key -Value $varHash.$key -Scope Script -Force
			} else { Set-Variable -Name "settingsVersion" -Value $varHash.$key -Scope Script -Force }
		}
	} else {
		$script:delay          = 750
		$script:loopDelay      = 300
		$script:sudoMode       = $false
		$script:skipPrejoining = $false
		$script:manualMode     = $false
		SaveSettings "delay", "loopDelay", "sudoMode", "version", "skipPrejoining", "manualMode", "VerbosePreference"
	}
	$script:delayInput.Text                  = $delay
	$script:loopDelayInput.Text              = $loopDelay
	$script:sudoModeCheckBox.IsChecked       = $sudomode
	$script:skipPrejoiningCheckbox.IsChecked = $skipPrejoining
	$script:manualModeCheckbox.IsChecked     = $manualMode
	if ($VerbosePreference -eq "Continue") { $script:verboseModeCheckbox.IsChecked = $true }
}
LoadSettings

function Join {
	$statusText.Text      = "Joining..."
	if (-not ($skipPrejoining)) {
		if ($sudoMode) {
			gsudo --integrity medium Start-Process "roblox://experiences/start?placeId=$rootId"
		} else {
			Start-Process "roblox://experiences/start?placeId=$rootId"
		}
		Write-Verbose "Pre-joining roblox://experiences/start?placeId=$rootId"
		while (-not (WindowInForeground "Roblox")) {
			Start-Sleep -Milliseconds $loopDelay
		}
		$process     = WindowInForeground "Roblox"
		$processPath = (Get-Process -Id $process.Id).Path
		$processName = [System.IO.Path]::GetFileNameWithoutExtension($processPath)
		if ($manualMode) {
			Start-Sleep -Milliseconds $delay
			Write-Verbose "Closing roblox..."
		} else {
			WaitForLogs "UgcExperienceController: initialize:"
			Write-Verbose '"UgcExperienceController:" initialize: found in logs. Closing roblox...'
		}
		Stop-Process -Name $processName
	}
	if ($sudoMode) {
		gsudo --integrity medium Start-Process "roblox://experiences/start?placeId=$subplace${jobIdString}"
	} else {
		Start-Process "roblox://experiences/start?placeId=$subplace${jobIdString}"
	}
	Write-Verbose "Joining roblox://experiences/start?placeId=$subplace${jobIdString}"
	while (-not (WindowInForeground "Roblox")) {
		Start-Sleep -Milliseconds $loopDelay
	}
	Write-Verbose "Roblox found. Blocking internet..."
	BlockInternet $processPath
	$statusDot.Foreground = [System.Windows.Media.Brushes]::Red
	$statusText.Text      = "Disconnected. Do not click on retry yet."
	if ($manualMode) {
		Start-Sleep -Milliseconds $delay
		Write-Verbose "Unblocking internet..."
	} else {
		WaitForLogs "Game join failed."
		Write-Verbose '"Game join failed." found in logs. Unblocking internet...'
	}
	UnblockInternet $processPath
	$statusDot.Foreground = [System.Windows.Media.Brushes]::Green
	$statusText.Text = "Connected. You can click on retry now."
	$script:timer = New-Object System.Windows.Threading.DispatcherTimer
	$timer.Interval = [TimeSpan]::FromSeconds(5)
	$timer.Add_Tick({
		$statusDot.Foreground = [System.Windows.Media.Brushes]::Gray
		$statusText.Text = "Joining process hasn't begun yet."
		$timer.Stop()
	})
	$timer.Start()
}

function WindowInForeground {
	param ($windowName)
	return Get-Process | Where-Object { $_.MainWindowTitle -match "^$windowName(?:\s\(Internal\))?$" }
}

function WaitForLogs {
	param ( [string]$searchString )
	$folderPath = "$env:LOCALAPPDATA\Roblox\logs"
	$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
	$timeout = 10
	while ($stopwatch.Elapsed.TotalSeconds -lt $timeout) {
		$file = Get-ChildItem $folderPath -File | Sort-Object -Descending -Property LastWriteTime | Select-Object -First 1
		if ($file -and (Select-String -Path $file.FullName -Pattern $searchString -SimpleMatch)) {
			return 
		}
		Start-Sleep -Milliseconds $LoopDelay
	}
}

function BlockInternet {
	param ($path)
	netsh advfirewall firewall add rule name="subplace inbound" dir=in action=block program=$path enable=yes | Out-Null
	netsh advfirewall firewall add rule name="subplace outbound" dir=out action=block program=$path enable=yes | Out-Null
}

function UnblockInternet {
	netsh advfirewall firewall delete rule name="subplace inbound" | Out-Null
	netsh advfirewall firewall delete rule name="subplace outbound" | Out-Null
}

$window.ShowDialog() | Out-Null
