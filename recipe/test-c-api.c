/* Documented AR shipping contract for library callers using libwhisper /
 * libparakeet with a GGML_BACKEND_DL ggml (ours comes from libllama 0.5.0+):
 * callers must call ggml_backend_load_all() once before any whisper / parakeet
 * / vad init, matching upstream ggml-org/whisper.cpp#3196 (removed implicit
 * loading) and #4031 (test harnesses explicitly call it).
 *
 * libllama 0.5.0's ggml-search-module-dir patch is what lets this call find
 * the backend plugins from any caller location (test binary runs from
 * test_tmp/, not $PREFIX/bin), via dladdr / GetModuleHandleExW on ggml itself.
 */
#include <stdio.h>
#include <ggml-backend.h>
#include <whisper.h>
#include <parakeet.h>

int main(int argc, char ** argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: %s <whisper-model> <parakeet-model> <vad-model>\n", argv[0]);
        return 2;
    }

    ggml_backend_load_all();
    printf("ggml devices: %zu\n", ggml_backend_dev_count());

    struct whisper_context * wctx = whisper_init_from_file_with_params(argv[1], whisper_context_default_params());
    printf("whisper context: %s\n", wctx ? "ok" : "FAILED");

    struct parakeet_context * pctx = parakeet_init_from_file_with_params(argv[2], parakeet_context_default_params());
    printf("parakeet context: %s\n", pctx ? "ok" : "FAILED");

    struct whisper_vad_context * vctx = whisper_vad_init_from_file_with_params(argv[3], whisper_vad_default_context_params());
    printf("vad context: %s\n", vctx ? "ok" : "FAILED");

    int ok = wctx && pctx && vctx;
    if (wctx) whisper_free(wctx);
    if (pctx) parakeet_free(pctx);
    if (vctx) whisper_vad_free(vctx);
    return ok ? 0 : 1;
}
