FROM registry.redhat.io/ubi8:latest

RUN mkdir /mkdir /logify && mkdir /vector-logs

COPY logify.sh /logify/logify.sh

RUN chgrp -R 0 /logify/ && chmod -R g=u /logify \
 && chgrp -R 0 /vector-logs && chmod -R g=u /vector-logs \
 && chmod g+x /logify/logify.sh


CMD ["/logify/logify.sh"]