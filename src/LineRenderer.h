#pragma once
#include "Renderer.h"

// currently supported rendering strategies
#include "RenderingStrategies/RenderingStrategy.h"
#include "UiRenderer.h"
#include "Audio/AudioPlayer.h"

#include <memory>
#include <deque>

#include <glm/glm.hpp>
#include <glbinding/gl/gl.h>
#include <glbinding/gl/enum.h>
#include <glbinding/gl/functions.h>

#include <globjects/VertexArray.h>
#include <globjects/VertexAttributeBinding.h>
#include <globjects/Buffer.h>
#include <globjects/Program.h>
#include <globjects/Shader.h>
#include <globjects/Framebuffer.h>
#include <globjects/Renderbuffer.h>
#include <globjects/Texture.h>
#include <globjects/base/File.h>
#include <globjects/TextureHandle.h>
#include <globjects/NamedString.h>
#include <globjects/base/StaticStringSource.h>
#include <globjects/Query.h>

namespace lineweaver
{
	class Viewer;

	class LineRenderer : public Renderer
	{
	public:
		LineRenderer(Viewer *viewer);
		virtual void display();
	private:
		void removeNonUnique(std::vector<int>& vec);


		LinkedListRendering* renderingStrategy = NULL;

		std::unique_ptr<globjects::VertexArray> m_vao = std::make_unique<globjects::VertexArray>();
		std::unique_ptr<globjects::Buffer> m_xColumnBuffer = std::make_unique<globjects::Buffer>();
		std::unique_ptr<globjects::Buffer> m_yColumnBuffer = std::make_unique<globjects::Buffer>();
		std::unique_ptr<globjects::Buffer> m_importanceColumnBuffer = std::make_unique<globjects::Buffer>();
		
		std::unique_ptr<globjects::VertexArray> m_vaoQuad = std::make_unique<globjects::VertexArray>();
		std::unique_ptr<globjects::Buffer> m_verticesQuad = std::make_unique<globjects::Buffer>();
		

		std::unique_ptr<globjects::StaticStringSource> m_shaderSourceDefines = nullptr;
		std::unique_ptr<globjects::NamedString> m_shaderDefines = nullptr;

		//SSBO
		std::unique_ptr<globjects::Buffer> m_intersectionBuffer = std::make_unique<globjects::Buffer>();

		//SSBO for overplotting measure implementation
		std::unique_ptr<globjects::Buffer> m_totalPixelBuffer = std::make_unique<globjects::Buffer>();
		std::unique_ptr<globjects::Buffer> m_visiblePixelBuffer = std::make_unique<globjects::Buffer>();
		
		//SSBO for detecting which lines are within the radius
		std::unique_ptr<globjects::Buffer> m_idBuffer = std::make_unique<globjects::Buffer>();

		std::unique_ptr<globjects::Texture> m_lineChartTexture = nullptr;
		std::unique_ptr<globjects::Texture> m_depthTexture = nullptr;
		std::unique_ptr<globjects::Texture> m_offsetTexture = nullptr;
		std::unique_ptr<globjects::Texture> m_blurTexture[2] = { nullptr, nullptr };
		std::unique_ptr<globjects::Texture> m_volumeTexture = nullptr;
		std::unique_ptr<globjects::Texture> m_IdTexture = nullptr;



		glm::ivec2 m_framebufferSize;

		std::unique_ptr<globjects::Framebuffer> m_blurFramebuffer = nullptr;
		std::unique_ptr<globjects::Framebuffer> m_lineFramebuffer = nullptr;

		// GUI variables ----------------------------------------------------------------------------
		UiRenderer m_uiRenderer;

		glm::vec2 m_lensPosition;
		glm::vec2 m_delayedLensPosition;


		std::vector<unsigned int> m_totalPixelsPerTrajectory;
		std::vector<unsigned int> m_visiblePixelsPerTrajectory;
		double m_overplottingRatio = 0.0;

		bool initLensPosition = true;

		// Animation
		double m_prevTime = NULL;
		float m_time = 0.0;
		float m_testTimer = 0.0;
		float m_foldTimer = 0.0;
		float m_pullTimer = 0.0;


		float m_delayTimer = 0.0;
		std::deque<glm::vec3> m_dlpQueue;

		bool m_dispAction = false;
		bool m_mouseMoving = false;
		bool m_mouseStopped = false;

		float m_previousLensDisp = 0.0f;
		const float ANIMATION_LENGTH = 0.5;

		// Audio
		gam::AudioPlayer m_AudioPlayer;
		bool m_foldButtonHold = false;
		float audioTimer = 0.0f;

		int prevPixelX = 0;
		int prevPixelY = 0;
		int prevID = -1;
		// ------------------------------------------------------------------------------------------
	};

}