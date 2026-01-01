namespace GUITest;

using System;
using System.Diagnostics;
using SDL3Native;
using Sedulous.RHI.Vulkan;
using Sedulous.Logging.Debug;
using Sedulous.Mathematics;
using Sedulous.Logging.Abstractions;
using Sedulous.Platform.SDL3;
using Sedulous.RHI;
using Sedulous.GUI;

class Program
{
	public static void Main()
	{
		ILogger logger = scope DebugLogger(.Trace);
		var windowSystem = scope SDL3WindowSystem("GUI Test", 1280, 720);

		var window = windowSystem.PrimaryWindow;

		var graphicsContext = scope VKGraphicsContext(logger);
		defer graphicsContext.Dispose();

		graphicsContext.CreateDevice(scope ValidationLayer(logger));

		Sedulous.RHI.SurfaceInfo surfaceInfo = *(Sedulous.RHI.SurfaceInfo*)&window.SurfaceInfo;

		SwapChainDescription swapChainDescription = CreateSwapChainDescription((.)window.Width, (.)window.Height, ref surfaceInfo);
		var swapChain = graphicsContext.CreateSwapChain(swapChainDescription);
		defer graphicsContext.DestroySwapChain(ref swapChain);

		var commandQueue = graphicsContext.Factory.CreateCommandQueue();
		defer graphicsContext.Factory.DestroyCommandQueue(ref commandQueue);

		window.OnResized.Add(scope (width, height) =>
			{
				commandQueue.WaitIdle();
				swapChain.ResizeSwapChain((.)width, (.)height);
			});

		// Create UI components
		var uiRenderer = scope RHIUIRenderer(graphicsContext, commandQueue, swapChain);
		var inputProvider = scope SDL3InputProvider(windowSystem.InputSystem);
		var fontProvider = scope DummyFontProvider();

		// Initialize theme and set font
		ThemeManager.Initialize();
		if (ThemeManager.Resources != null)
			ThemeManager.Resources.DefaultFont = fontProvider.DefaultFont;

		// Create UI application
		var uiApp = scope UIApplication(uiRenderer, inputProvider, fontProvider);

		// Build sample UI
		var root = BuildSampleUI();
		defer delete root;

		uiApp.SetRoot(root);

		windowSystem.StartMainLoop();
		while (windowSystem.IsRunning)
		{
			windowSystem.RunOneFrame(scope (elapsedTime) =>
				{
					// Update UI
					uiApp.Update(elapsedTime / (float)TimeSpan.TicksPerSecond);

					// Render UI
					uiApp.Render();
				});
		}
		commandQueue.WaitIdle();
		windowSystem.StopMainLoop();

		// Cleanup theme resources
		ThemeManager.Shutdown();
	}

	private static UIElement BuildSampleUI()
	{
		// Create main panel with dark background
		var mainPanel = new StackPanel();
		mainPanel.Orientation = .Vertical;
		mainPanel.Margin = .(20);

		// Title
		var title = new TextBlock();
		title.Text = "GUI Test Sample";
		title.Margin = .(0, 0, 0, 20);
		mainPanel.AddChild(title);

		// Buttons row
		var buttonRow = new StackPanel();
		buttonRow.Orientation = .Horizontal;
		buttonRow.Spacing = 10;
		buttonRow.Margin = .(0, 0, 0, 20);

		var button1 = new Button();
		var button1Text = new TextBlock();
		button1Text.Text = "Click Me";
		button1.Child = button1Text;
		button1.Click.Add(new (btn) =>
			{
				Console.WriteLine("Button 1 clicked!");
			});
		buttonRow.AddChild(button1);

		var button2 = new Button();
		var button2Text = new TextBlock();
		button2Text.Text = "Another Button";
		button2.Child = button2Text;
		button2.Click.Add(new (btn) =>
			{
				Console.WriteLine("Button 2 clicked!");
			});
		buttonRow.AddChild(button2);

		mainPanel.AddChild(buttonRow);

		// Checkbox section
		var checkboxSection = new StackPanel();
		checkboxSection.Orientation = .Vertical;
		checkboxSection.Margin = .(0, 0, 0, 20);

		var checkbox1 = new CheckBox();
		var checkbox1Label = new TextBlock();
		checkbox1Label.Text = "Enable feature A";
		checkbox1.Content = checkbox1Label;
		checkbox1.CheckedChanged.Add(new (cb, isChecked) =>
			{
				Console.WriteLine(scope $"Checkbox 1: {isChecked}");
			});
		checkboxSection.AddChild(checkbox1);

		var checkbox2 = new CheckBox();
		var checkbox2Label = new TextBlock();
		checkbox2Label.Text = "Enable feature B";
		checkbox2.Content = checkbox2Label;
		checkbox2.IsChecked = true;
		checkboxSection.AddChild(checkbox2);

		mainPanel.AddChild(checkboxSection);

		// Slider section
		var sliderSection = new StackPanel();
		sliderSection.Orientation = .Vertical;
		sliderSection.Margin = .(0, 0, 0, 20);

		var sliderLabel = new TextBlock();
		sliderLabel.Text = "Volume: 50";
		sliderSection.AddChild(sliderLabel);

		var slider = new Slider();
		slider.Minimum = 0;
		slider.Maximum = 100;
		slider.Value = 50;
		slider.Width = 300;
		slider.ValueChanged.Add(new (sl, value) =>
			{
				sliderLabel.Text = scope $"Volume: {(int)value}";
			});
		sliderSection.AddChild(slider);

		mainPanel.AddChild(sliderSection);

		// Grid demo
		var gridLabel = new TextBlock();
		gridLabel.Text = "Grid Layout Demo:";
		gridLabel.Margin = .(0, 0, 0, 10);
		mainPanel.AddChild(gridLabel);

		var grid = new Grid();
		grid.Width = 400;
		grid.Height = 200;

		// Define columns
		grid.ColumnDefinitions.Add(new .() { Width = .Star(1) });
		grid.ColumnDefinitions.Add(new .() { Width = .Star(1) });

		// Define rows
		grid.RowDefinitions.Add(new .() { Height = .Star(1) });
		grid.RowDefinitions.Add(new .() { Height = .Star(1) });

		// Add cells
		for (int row < 2)
		{
			for (int col < 2)
			{
				var cell = new Border();
				cell.BackgroundOverride = Color((uint8)(100 + row * 50), (uint8)(100 + col * 50), 150, 255);
				cell.BorderBrushOverride = Color(200, 200, 200, 255);
				cell.BorderThicknessOverride = .(1);
				cell.Margin = .(2);

				var cellText = new TextBlock();
				cellText.Text = scope:: $"Cell ({row},{col})";
				cell.Child = cellText;

				grid.SetRow(cell, (.)row);
				grid.SetColumn(cell, (.)col);
				grid.AddChild(cell);
			}
		}

		mainPanel.AddChild(grid);

		// Dialog button
		var dialogButton = new Button();
		var dialogButtonText = new TextBlock();
		dialogButtonText.Text = "Show Dialog";
		dialogButton.Child = dialogButtonText;
		dialogButton.Margin = .(0, 20, 0, 0);
		dialogButton.Click.Add(new (btn) =>
			{
				var dialog = new Dialog();
				dialog.Title = "Sample Dialog";
				dialog.MinWidth = 300;

				var content = new TextBlock();
				content.Text = "This is a modal dialog.\nClick OK or Cancel to close.";
				dialog.SetContent(content);

				dialog.AddButton("OK", .OK);
				dialog.AddButton("Cancel", .Cancel);

				dialog.Closed.Add(new (dlg, result) =>
					{
						Console.WriteLine(scope $"Dialog closed with result: {result}");
						delete dlg;
					});

				dialog.Show();
			});
		mainPanel.AddChild(dialogButton);

		return mainPanel;
	}

	private static SwapChainDescription CreateSwapChainDescription(uint32 width, uint32 height, ref SurfaceInfo surfaceInfo)
	{
		return SwapChainDescription()
			{
				Width = width,
				Height = height,
				SurfaceInfo = surfaceInfo,
				ColorTargetFormat = PixelFormat.R8G8B8A8_UNorm,
				ColorTargetFlags = TextureFlags.RenderTarget | TextureFlags.ShaderResource,
				DepthStencilTargetFormat = PixelFormat.D24_UNorm_S8_UInt,
				DepthStencilTargetFlags = TextureFlags.DepthStencil,
				SampleCount = TextureSampleCount.None,
				IsWindowed = true,
				RefreshRate = 60
			};
	}
}
