FROM registry.redhat.io/ubi9:latest
RUN bash -c "$(curl -L https://setup.vector.dev)" \
    && yum install -y vector \
    && mkdir /vector-config \
    && mkdir /vector-data-dir
RUN chgrp -R 0 /vector-config \
&& chmod -R g=u /vector-config && chgrp -R 0 /vector-data-dir && chmod -R g=u /vector-data-dir
CMD ["vector", "-q","-c", "/vector-config/vector.yaml"]
