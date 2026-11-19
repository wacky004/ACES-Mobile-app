#include "ocr_channel.h"

#include <cstring>
#include <memory>
#include <string>
#include <vector>

#include <flutter/encodable_value.h>
#include <flutter/flutter_engine.h>
#include <flutter/method_channel.h>
#include <flutter/method_call.h>
#include <flutter/standard_method_codec.h>

#include <winrt/Windows.Foundation.h>
#include <winrt/Windows.Graphics.Imaging.h>
#include <winrt/Windows.Media.Ocr.h>
#include <winrt/Windows.Storage.Streams.h>

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResult;

int ReadInt(const EncodableMap& map, const char* key, int fallback) {
  const auto it = map.find(EncodableValue(key));
  if (it == map.end()) return fallback;
  if (const auto* value = std::get_if<int32_t>(&it->second)) return *value;
  if (const auto* value = std::get_if<int64_t>(&it->second)) {
    return static_cast<int>(*value);
  }
  return fallback;
}

winrt::fire_and_forget RecognizeTextAsync(
    std::vector<uint8_t> bytes, int width, int height,
    std::unique_ptr<MethodResult<EncodableValue>> result) {
  auto ui_thread = winrt::apartment_context();
  std::string error_code;
  std::string error_message;
  std::string text;

  try {
    if (width <= 0 || height <= 0 ||
        bytes.size() != static_cast<size_t>(width) * height * 4) {
      error_code = "invalid_image";
      error_message = "The rendered page was not valid BGRA.";
    } else {
      auto bitmap = winrt::Windows::Graphics::Imaging::SoftwareBitmap(
          winrt::Windows::Graphics::Imaging::BitmapPixelFormat::Bgra8, width,
          height,
          winrt::Windows::Graphics::Imaging::BitmapAlphaMode::Premultiplied);
      auto buffer = winrt::Windows::Storage::Streams::Buffer(
          static_cast<uint32_t>(bytes.size()));
      buffer.Length(static_cast<uint32_t>(bytes.size()));
      std::memcpy(buffer.data(), bytes.data(), bytes.size());
      bitmap.CopyFromBuffer(buffer);

      auto engine = winrt::Windows::Media::Ocr::OcrEngine::
          TryCreateFromUserProfileLanguages();
      if (!engine) {
        error_code = "ocr_unavailable";
        error_message =
            "Windows OCR is not available for this user language.";
      } else {
        auto ocr = co_await engine.RecognizeAsync(bitmap);
        text = winrt::to_string(ocr.Text());
      }
    }
  } catch (const winrt::hresult_error& error) {
    error_code = "ocr_error";
    error_message = winrt::to_string(error.message());
  } catch (...) {
    error_code = "ocr_error";
    error_message = "Windows OCR failed.";
  }

  co_await ui_thread;
  if (!error_code.empty()) {
    result->Error(error_code, error_message);
  } else {
    result->Success(EncodableValue(text));
  }
}

std::unique_ptr<flutter::MethodChannel<EncodableValue>> g_channel;

}  // namespace

void RegisterOcrChannel(flutter::FlutterEngine* engine) {
  if (engine == nullptr) return;
  g_channel = std::make_unique<flutter::MethodChannel<EncodableValue>>(
      engine->messenger(), "aces/ocr",
      &flutter::StandardMethodCodec::GetInstance());
  g_channel->SetMethodCallHandler(
      [](const MethodCall<EncodableValue>& call,
         std::unique_ptr<MethodResult<EncodableValue>> result) {
        if (call.method_name() != "recognizeText") {
          result->NotImplemented();
          return;
        }
        const auto* arguments =
            std::get_if<EncodableMap>(call.arguments());
        if (arguments == nullptr) {
          result->Error("invalid_arguments", "Expected an OCR image.");
          return;
        }
        const auto bytes_it = arguments->find(EncodableValue("bytes"));
        if (bytes_it == arguments->end()) {
          result->Error("invalid_arguments", "Missing image bytes.");
          return;
        }
        const auto* bytes =
            std::get_if<std::vector<uint8_t>>(&bytes_it->second);
        if (bytes == nullptr) {
          result->Error("invalid_arguments", "Invalid image bytes.");
          return;
        }
        const auto width = ReadInt(*arguments, "width", 0);
        const auto height = ReadInt(*arguments, "height", 0);
        RecognizeTextAsync(*bytes, width, height, std::move(result));
      });
}
