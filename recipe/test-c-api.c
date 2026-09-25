/* Documented C API model init, without calling ggml_backend_load_all():
 * libraries must find ggml's backends on their own (run outside $PREFIX/bin). */
#include <stdio.h>
#include <whisper.h>
#include <parakeet.h>

int main(int argc, char ** argv) {
    if (argc != 4) {
        fprintf(stderr, "usage: %s <whisper-model> <parakeet-model> <vad-model>\n", argv[0]);
        return 2;
    }

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
