

   // io `File`

      static void io_File_read_(WrenVM *vm) {
      } //io_File_read_

      static void io_File_write_(WrenVM *vm) {
      } //io_File_write_

      static void io_File_seek_(WrenVM *vm) {
      } //io_File_seek_

      static void io_File_tell_(WrenVM *vm) {
      } //io_File_tell_

      static void io_File_close_(WrenVM *vm) {
      } //io_File_close_

   // io `Dir`

      static void io_Dir_exists_(WrenVM *vm) {
      } //io_Dir_exists_

      static void io_Dir_make_(WrenVM *vm) {
      } //io_Dir_make_

      static void io_Dir_list_(WrenVM *vm) {
      } //io_Dir_list_

   // process `Process`

      static void process_Process_arguments(WrenVM *vm) {
      } //process_Process_arguments

      static void process_Process_allArguments(WrenVM *vm) {
      } //process_Process_allArguments



static WrenForeignMethodFn bind_io_method(WrenVM* vm, bool is_static, const char* signature) {

   // io `File`

      if(strcmp(signature, "read_(_)") == 0)      return io_File_read_;
      if(strcmp(signature, "write_(_,_)") == 0)   return io_File_write_;
      if(strcmp(signature, "seek_(_,_)") == 0)    return io_File_seek_;
      if(strcmp(signature, "tell_()") == 0)       return io_File_tell_;
      if(strcmp(signature, "close_()") == 0)      return io_File_close_;

   // io `Dir`

      if(strcmp(signature, "exists_(_)") == 0)   return io_Dir_exists_;
      if(strcmp(signature, "make_(_,_)") == 0)   return io_Dir_make_;
      if(strcmp(signature, "list_(_,_)") == 0)   return io_Dir_list_;

   return nullptr;

} //bind_io_method

static WrenForeignMethodFn bind_process_method(WrenVM* vm, bool is_static, const char* signature) {

   // process `Process`

      if(strcmp(signature, "arguments(_)") == 0)        return process_Process_arguments;
      if(strcmp(signature, "allArguments(_,_)") == 0)   return process_Process_allArguments;

   return nullptr;

} //bind_process_method



   //This code is for inside of the bindForeignMethodFn function you give wren
   //you only need the body, but it includes the rest for example
static WrenForeignMethodFn bind_method(WrenVM* vm, const char* module, const char* class_name, bool is_static, const char* signature) {

   if(strcmp(module, "io") == 0) return bind_io_method(vm, is_static, signature);
   if(strcmp(module, "process") == 0) return bind_process_method(vm, is_static, signature);

   return nullptr;

} //bind_method



