var SHADOWS = false;
var MAX_PARTICLES = 300;
var MAX_VELOCITY = 200;
var PARTICLE_RADIUS = 6;
var STAGE_WIDTH = 320; //window.innerWidth;
var STAGE_HEIGHT = 320; //window.innerHeight;
var COLORS = ["#cc0000", "#ffcc00", "#aaff00", "#0099cc", "#194c99", "#661999"];
var FRAME_TIMES = [];

var particles = [];
var context = null;

function init()
{

	// Create the canvas
	var benchmark = document.getElementById('canvas');
	
	canvas.width = STAGE_WIDTH;
	canvas.height = STAGE_HEIGHT;

	
	// Create the particles
	for (var i = 0; i < MAX_PARTICLES; i++)
	{
		particles.push(new Particle());
	}
	
	if (typeof benchmark.getContext == "undefined")
	{
		// Try using exCanvas for Internet Explorer
		try
		{
			G_vmlCanvasManager.initElement(benchmark);
		}
		catch (error)
		{
			alert("Sorry, your browser doesn't support CANVAS");
			
			return;
		}
	}
	
	context = benchmark.getContext("2d");
	context.fillStyle = '#ffffff';
	context.fillRect(0, 0, STAGE_WIDTH, STAGE_HEIGHT);
	
	// Start the animation
	setInterval(animate, 1);
}

function animate()
{
	// Limit the frame time array to the last 30 frames
	if (FRAME_TIMES.length > 30)
	{
		FRAME_TIMES.splice(0, 1);
	}
	
	var currTime = new Date().getTime();
	
	FRAME_TIMES.push(currTime);
	
	// Calculate the framerate based upon the difference between the absolute times of the oldest and newest frames, subdivided by how many frames were drawn inbetween
	// var frameRate = document.getElementById("frameRate");
	var frameRateText = 1000 / ((currTime - FRAME_TIMES[0]) / (FRAME_TIMES.length - 1)) + "";
	frameRateText = frameRateText.replace(/(^[^.]+\...).*/, "$1");
	frameRateText += " FPS";
	console.log(frameRateText);
	//frameRate.innerHTML = frameRateText;
	
	var timeDelta = currTime - FRAME_TIMES[FRAME_TIMES.length - 2];
	
	if (isNaN(timeDelta))
	{
		timeDelta = 0;
	}
	
	context.clearRect(0, 0, STAGE_WIDTH, STAGE_HEIGHT);
	
	// Draw each particle
	for (var particle in particles)
	{
		particles[particle].draw(timeDelta);
	}
}

function Particle()
{
	var angle = Math.PI * 2 * Math.random();
	var velocity = MAX_VELOCITY / 8 * 7 * Math.random() + MAX_VELOCITY / 8;
	var x = STAGE_WIDTH / 2 - PARTICLE_RADIUS;
	var y = STAGE_HEIGHT / 2 - PARTICLE_RADIUS;
	var color = COLORS[Math.floor(Math.random() * COLORS.length)];
	
	function draw(timeDelta)
	{
		// Calculate next position of particle
		var nextX = x + Math.cos(angle) * velocity * (timeDelta / 1000);
		var nextY = y + Math.sin(angle) * velocity * (timeDelta / 1000);
		
		// If particle is going to move off right side of screen
		if (nextX + PARTICLE_RADIUS * 2 > STAGE_WIDTH)
		{
			// If angle is between 3 o'clock and 6 o'clock
			if ((angle >= 0 && angle < Math.PI / 2))
			{
				angle = Math.PI - angle;
			}
			// If angle is between 12 o'clock and 3 o'clock
			else if (angle > Math.PI / 2 * 3)
			{
				angle = angle - (angle - Math.PI / 2 * 3) * 2
			}
		}
		
		// If particle is going to move off left side of screen
		if (nextX < 0)
		{
			// If angle is between 6 o'clock and 9 o'clock
			if ((angle > Math.PI / 2 && angle < Math.PI))
			{
				angle = Math.PI - angle;
			}
			// If angle is between 9 o'clock and 12 o'clock
			else if (angle > Math.PI && angle < Math.PI / 2 * 3)
			{
				angle = angle + (Math.PI / 2 * 3 - angle) * 2
			}
		}
		
		// If particle is going to move off bottom side of screen
		if (nextY + PARTICLE_RADIUS * 2 > STAGE_HEIGHT)
		{
			// If angle is between 3 o'clock and 9 o'clock
			if ((angle > 0 && angle < Math.PI))
			{
				angle = Math.PI * 2 - angle;
			}
		}
		
		// If particle is going to move off top side of screen
		if (nextY < 0)
		{
			// If angle is between 9 o'clock and 3 o'clock
			if ((angle > Math.PI && angle < Math.PI * 2))
			{
				angle = angle - (angle - Math.PI) * 2;
			}
		}

		if (SHADOWS)
		{
			context.shadowOffsetX = 4;
			context.shadowOffsetY = 4;
			context.shadowBlur = 3;
			context.shadowColor = "rgba(0, 0, 0, 0.33)";
		}

		context.fillStyle = color;
		context.beginPath();
		context.arc(nextX, nextY, PARTICLE_RADIUS, 0, Math.PI * 2, true);
		context.fill();
		
		x = nextX;
		y = nextY;
	}
	
	return {
		draw: draw
	}
}

init();
	