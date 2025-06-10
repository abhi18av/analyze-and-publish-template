process HELLO {

        shell:
        '''
            echo "Hello, world!"
        '''

}

workflow {
         HELLO()
}
