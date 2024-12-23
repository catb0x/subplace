<#
subplacegui.ps1
by kit, version 1.1
subject to the terms of the MPL 2.0, you can get a copy at http://mozilla.org/MPL/2.0/
#>

$version  = "1.1"
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
				<StackPanel Orientation="Horizontal" Margin="10">
					<TextBox x:Name="PlaceIdInput" Width="150" Margin="0,0,10,0"/>
					<Button Content="Set PlaceId" x:Name="SetPlaceIdButton"/>
				</StackPanel>
				<DataGrid x:Name="PlacesGrid" Grid.Row="1" AutoGenerateColumns="False" Margin="10" IsReadOnly="True" HeadersVisibility="Column" VirtualizingPanel.ScrollUnit="Pixel">
					<DataGrid.Columns>
						<DataGridTextColumn Header="Name" Binding="{Binding name}" Width="*"/>
						<DataGridTextColumn Header="ID" Binding="{Binding id}" Width="Auto"/>
					</DataGrid.Columns>
				</DataGrid>
				<StackPanel Grid.Row="2" Margin="10,0,10,10" Orientation="Horizontal">
					<TextBlock x:Name="StatusDot" Foreground="Gray" FontFamily="Segoe UI Symbol Regular">&#x26AB;</TextBlock>
					<TextBlock x:Name="StatusText">&#x2002;Joining process hasn't begun yet.</TextBlock>
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
					<StackPanel Orientation="Horizontal" Margin="-5,0,0,0">
						<Label Content="Delay:" Target="{Binding ElementName=Delay}"/>
						<TextBox x:Name="Delay" Text="750" HorizontalAlignment="Left" Width="150" Height="18"/>
					</StackPanel>
					<StackPanel Orientation="Horizontal" Margin="-5,0,0,8">
						<Label Content="Loop Delay:" Target="{Binding ElementName=LoopDelay}"/>
						<TextBox x:Name="LoopDelay" Text="300" HorizontalAlignment="Left" Width="150" Height="18"/>
					</StackPanel>
					<CheckBox x:Name="SudoMode" Content="Enable sudo mode" Margin="0,0,0,10"/>
					<CheckBox x:Name="SkipPrejoining" Content="Skip pre-joining" Margin="0,0,0,10"/>
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
			<StackPanel Margin="10">
				<TextBlock Margin="0,0,0,5">subplacegui 1.1 by Kit</TextBlock>
				<TextBlock Margin="0,0,0,5"><Hyperlink x:Name="GithubLink" NavigateUri="https://github.com/catb0x/subplace">Github</Hyperlink></TextBlock>
				<TextBlock Margin="0,0,0,5" Foreground="Gray">stan loona :3</TextBlock>
    				<TextBlock Margin="0,0,0,5" Foreground="Gray">rgc was here</TextBlock>
			</StackPanel>
		</TabItem>
	</TabControl>
</Window>
"@

$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$window = [Windows.Markup.XamlReader]::Load($reader)

$placeIdInput       = $window.FindName("PlaceIdInput")
$setPlaceIdButton   = $window.FindName("SetPlaceIdButton")
$placesGrid         = $window.FindName("PlacesGrid")
$delayInput         = $window.FindName("Delay")
$loopDelayInput     = $window.FindName("LoopDelay")
$sudoModeCheckbox   = $window.FindName("SudoMode")
$saveSettingsButton = $window.FindName("SaveSettingsButton")
$savedMessageText   = $window.FindName("SavedMessage")
$skipPrejoining     = $window.FindName("SkipPrejoining")
$statusText         = $window.FindName("StatusText")
$statusDot          = $window.FindName("StatusDot")
$githubLink         = $window.FindName("GithubLink")

$fadeOut = New-Object Windows.Media.Animation.DoubleAnimation
$fadeOut.From = 1.0
$fadeOut.To = 0.0
$fadeOut.Duration = [System.Windows.Duration]::new([System.TimeSpan]::FromSeconds(0.5))

if (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
	Start-Process powershell -ArgumentList "-NoExit", "-noprofile", "-executionpolicy bypass", "-file `"$PSCommandPath`"" -Verb RunAs
	exit
} elseif (!(Get-Command "gsudo" -ErrorAction SilentlyContinue)) {
	$sudoModeCheckbox.Visibility = [System.Windows.Visibility]::Collapsed
}

$githubLink.Add_Click({
	Start-Process $this.NavigateUri.AbsoluteUri
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

$setPlaceIdButton.Add_Click({
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
	SaveSettings "delay", "loopDelay", "sudoMode", "version"
})

$placesGrid.Add_MouseDoubleClick({
	if ($placesGrid.SelectedItem) {
		$script:subplace = $placesGrid.SelectedItem.id
		Join
	}
})

$sudoModeCheckBox.Add_Checked({
	$script:sudoMode = $true
})

$sudoModeCheckBox.Add_Unchecked({
	$script:sudoMode = $false
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
			Set-Variable -Name $key -Value $varHash.$key -Scope Script -Force
		}
	} else {
		$script:delay     = 750
		$script:loopDelay = 300
		$script:sudoMode  = $false
		SaveSettings "delay", "loopDelay", "sudoMode", "version"
	}
	$script:delayInput.Text            = $delay
	$script:loopDelayInput.Text        = $loopDelay
	$script:sudoModeCheckbox.IsChecked = $sudoMode
}
LoadSettings

function Join {
	$statusDot.Foreground = [System.Windows.Media.Brushes]::Red
	$statusText.Text      = " Do not click on retry yet."
	if (-not ($skipPrejoining.IsChecked)) {
		if ($sudoMode) {
			gsudo --integrity medium Start-Process "roblox://experiences/start?placeId=$rootId"
		} else {
			Start-Process "roblox://experiences/start?placeId=$rootId"
		}
		while (-not (WindowInForeground "Roblox")) {
			Start-Sleep -Milliseconds $loopDelay
		}
		$process     = WindowInForeground "Roblox"
		$processPath = (Get-Process -Id $process.Id).Path
		$processName = [System.IO.Path]::GetFileNameWithoutExtension($processPath)
		Start-Sleep -Milliseconds $delay
		Stop-Process -Name $processName
	}
	if ($sudoMode) {
		gsudo --integrity medium Start-Process "roblox://experiences/start?placeId=$subplace"
	} else {
		Start-Process "roblox://experiences/start?placeId=$subplace"
	}
	while (-not (WindowInForeground "Roblox")) {
		Start-Sleep -Milliseconds $loopDelay
	}
	BlockInternet $processPath
	Start-Sleep -Milliseconds $delay
	UnblockInternet $processPath
	$statusDot.Foreground = [System.Windows.Media.Brushes]::Green
	$statusText.Text = " You can click on retry now."
	$script:timer = New-Object System.Windows.Threading.DispatcherTimer
	$timer.Interval = [TimeSpan]::FromSeconds(5)
	$timer.Add_Tick({
		$statusDot.Foreground = [System.Windows.Media.Brushes]::Gray
		$statusText.Text = " Joining process hasn't begun yet."
		$timer.Stop()
	})
$timer.Start()
}

function WindowInForeground {
	param ($windowName)
	return Get-Process | Where-Object { $_.MainWindowTitle -like $windowName }
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
